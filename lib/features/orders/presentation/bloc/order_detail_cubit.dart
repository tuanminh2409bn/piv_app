// lib/features/orders/presentation/bloc/order_detail_cubit.dart

import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/data/models/order_item_model.dart';
import 'package:piv_app/data/models/payment_info_model.dart';
import 'package:piv_app/data/models/user_model.dart';
// +++ THÊM IMPORT VOUCHER +++
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';
import 'package:piv_app/features/vouchers/domain/repositories/voucher_repository.dart';
// +++ KẾT THÚC THÊM +++
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart'; // Cần để lấy user info
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:piv_app/features/returns/data/models/return_request_model.dart';
import 'package:piv_app/features/returns/domain/repositories/return_repository.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_settings_repository.dart';
import 'package:piv_app/features/admin/data/models/discount_policy_model.dart';
import 'package:cloud_functions/cloud_functions.dart';

part 'order_detail_state.dart';

class OrderDetailCubit extends Cubit<OrderDetailState> {
  final OrderRepository _orderRepository;
  final UserProfileRepository _userProfileRepository;
  final ReturnRepository _returnRepository;
  final VoucherRepository _voucherRepository;
  final AuthBloc _authBloc;
  final AdminSettingsRepository _adminSettingsRepository;
  final FirebaseFunctions _functions;

  StreamSubscription<OrderModel>? _orderSubscription;
  StreamSubscription<ReturnRequestModel>? _returnRequestSubscription;

  OrderDetailCubit({
    required OrderRepository orderRepository,
    required UserProfileRepository userProfileRepository,
    required ReturnRepository returnRepository,
    required VoucherRepository voucherRepository,
    required AuthBloc authBloc,
    required AdminSettingsRepository adminSettingsRepository,
    required FirebaseFunctions functions,
  })  : _orderRepository = orderRepository,
        _userProfileRepository = userProfileRepository,
        _returnRepository = returnRepository,
        _voucherRepository = voucherRepository,
        _authBloc = authBloc,
        _adminSettingsRepository = adminSettingsRepository,
        _functions = functions,
        super(const OrderDetailState());

  // --- listenToOrderDetail giữ nguyên logic load order ban đầu ---
  void listenToOrderDetail(String orderId) {
    if (orderId.isEmpty) {
      emit(state.copyWith(status: OrderDetailStatus.error, errorMessage: 'ID đơn hàng không hợp lệ.'));
      return;
    }
    // Chỉ set loading nếu đang là initial
    if (state.status == OrderDetailStatus.initial) {
      emit(state.copyWith(status: OrderDetailStatus.loading));
    }
    _orderSubscription?.cancel();

    _orderSubscription = _orderRepository.getOrderStreamById(orderId).listen(
          (order) async {
        developer.log("Received update for order ${order.id}. Status: ${order.status}", name: "OrderDetailCubit");

        UserModel? placedByUser;
        if (order.placedBy != null && order.placedBy!.userId.isNotEmpty) {
          // Chỉ fetch lại placedByUser nếu chưa có hoặc ID thay đổi (hiếm)
          if (state.placedByUser == null || state.placedByUser!.id != order.placedBy!.userId) {
            final userResult = await _userProfileRepository.getUserProfile(order.placedBy!.userId);
            userResult.fold(
                  (failure) => placedByUser = null,
                  (user) => placedByUser = user,
            );
          } else {
            placedByUser = state.placedByUser;
          }
        }

        // --- QUAN TRỌNG: Giữ lại voucher state hiện tại nếu có ---
        // Tránh việc reset voucher mỗi khi order stream update (ví dụ khi admin xem)
        VoucherModel? currentAppliedVoucher = state.appliedVoucher;
        double currentVoucherDiscount = state.voucherDiscount;
        // Nếu order update từ Firestore có discount > 0 và cubit chưa có voucher,
        // có thể thử load lại voucher nếu cần (ít xảy ra)
        if (order.discount > 0 && currentAppliedVoucher == null) {
          // Tạm thời bỏ qua việc load lại voucher khi stream update,
          // tập trung vào việc user tự apply/remove
          currentVoucherDiscount = order.discount; // Lấy discount từ order nếu chưa có voucher
        }


        _returnRequestSubscription?.cancel();
        if (order.returnInfo?.returnRequestId != null && order.returnInfo!.returnRequestId.isNotEmpty) {
          // Chỉ listen lại nếu ID thay đổi hoặc chưa có subscription
          if (state.returnRequest == null || state.returnRequest!.id != order.returnInfo!.returnRequestId) {
            _returnRequestSubscription = _returnRepository
                .watchReturnRequestById(order.returnInfo!.returnRequestId)
                .listen((returnRequest) {
              emit(state.copyWith(returnRequest: returnRequest));
            }, onError: (e) {
              developer.log("Error watching return request: $e", name: "OrderDetailCubit");
              // Có thể emit lỗi nhẹ ở đây nếu cần
            });
          }
        } else {
          // Nếu order không còn return info, đảm bảo state returnRequest là null
          if (state.returnRequest != null) {
            emit(state.copyWith(returnRequest: null)); // Cần định nghĩa copyWith cho phép set null
          }
        }

        emit(state.copyWith(
          // Chỉ set status thành success nếu đang loading hoặc initial
          status: (state.status == OrderDetailStatus.loading || state.status == OrderDetailStatus.initial)
              ? OrderDetailStatus.success
              : state.status, // Giữ status hiện tại (ví dụ: applyingVoucher, error...)
          order: order,
          placedByUser: placedByUser, // Đã lấy ở trên
          // Giữ lại voucher state
          appliedVoucher: currentAppliedVoucher,
          voucherDiscount: currentVoucherDiscount,
        ));

        // Nếu đơn hàng đang chờ duyệt, thực hiện tính toán lại
        if (order.status == 'pending_approval') {
          await _recalculateAndLoadVouchers(order);
        }

        // Chỉ fetch payment info lần đầu hoặc khi cần
        if (order.paymentStatus == 'unpaid' && state.paymentInfo == null) {
          _fetchPaymentInfo();
        }
      },
      onError: (error) {
        developer.log("Error listening to order: $error", name: "OrderDetailCubit");
        emit(state.copyWith(status: OrderDetailStatus.error, errorMessage: 'Lỗi lắng nghe đơn hàng: $error'));
      },
    );
  }


  Future<void> _fetchPaymentInfo() async {
    // ... (hàm này giữ nguyên) ...
    if (state.paymentInfo != null) return;
    final result = await _orderRepository.getPaymentInfo();
    result.fold(
          (failure) => developer.log("Could not fetch payment info: ${failure.message}", name: "OrderDetailCubit"),
          (info) => emit(state.copyWith(paymentInfo: info)),
    );
  }

  // +++ HÀM MỚI: applyVoucher +++
  Future<void> _recalculateAndLoadVouchers(OrderModel order) async {
    try {
      final agentResult = await _userProfileRepository.getUserProfile(order.userId);
      final agent = agentResult.fold((l) => null, (r) => r);
      if (agent == null) return;

      final policy = await _adminSettingsRepository.getDiscountPolicy();

      double commissionDiscount = 0.0;
      final isDiscountAllowed = await _checkIfPromotionAllowed(agent, isDiscount: true, policy: policy);
      final allowPromotionDuringCommitment = await _checkIfPromotionAllowedDuringCommitment(agent, policy: policy);

      bool shouldCalculateDiscount = isDiscountAllowed && order.items.isNotEmpty;
      if (agent.activeRewardProgram == 'sales_commitment' && !allowPromotionDuringCommitment) {
        shouldCalculateDiscount = false;
      }

      if (shouldCalculateDiscount) {
        try {
          final HttpsCallable callable = _functions.httpsCallable('calculateOrderDiscount');
          final itemsPayload = order.items.map((item) => {
            'productId': item.productId,
            'subtotal': item.price * item.quantityPerPackage * item.quantity,
          }).toList();
          final response = await callable.call({'items': itemsPayload, 'agentId': agent.id});
          commissionDiscount = (response.data['discount'] as num).toDouble();
        } catch (e) {
          developer.log("Error recalculating commission discount: $e", name: "OrderDetailCubit");
        }
      }

      double seasonalDiscount = 0.0;
      if (order.items.isNotEmpty) {
        final now = DateTime.now();
        bool isInPromoPeriod = true;
        if (policy.seasonalDiscountStart != null && now.isBefore(policy.seasonalDiscountStart!)) {
          isInPromoPeriod = false;
        }
        if (policy.seasonalDiscountEnd != null && now.isAfter(policy.seasonalDiscountEnd!)) {
          isInPromoPeriod = false;
        }
        if (policy.seasonalDiscountEnabled && isInPromoPeriod && (agent.activeRewardProgram != 'sales_commitment' || allowPromotionDuringCommitment)) {
          seasonalDiscount = order.subtotal * policy.seasonalDiscountRate;
        }
      }

      final isVoucherAllowed = await _checkIfPromotionAllowed(agent, isDiscount: false, policy: policy);
      List<VoucherModel> availableVouchers = [];
      if (isVoucherAllowed) {
        final voucherResult = await _voucherRepository.getActiveVouchers();
        final allActiveVouchers = voucherResult.getOrElse(() => []);
        
        final Map<String, String> creatorRolesCache = {};
        final creatorIds = allActiveVouchers.map((v) => v.createdBy).where((id) => id.isNotEmpty).toSet();
        await Future.wait(creatorIds.map((id) async {
          final profileResult = await _userProfileRepository.getUserProfile(id);
          profileResult.fold(
            (failure) => null,
            (userProfile) => creatorRolesCache[id] = userProfile.role,
          );
        }));

        availableVouchers = _filterVouchers(order.items, agent, allowPromotionDuringCommitment, allActiveVouchers, creatorRolesCache);
      }

      final isStackingAllowed = await _checkIfStackingAllowed(agent, policy: policy);
      double currentVoucherDiscount = state.voucherDiscount;
      double finalCommission = (state.appliedVoucher != null && !isStackingAllowed) ? 0.0 : commissionDiscount;

      final double subtotal = order.subtotal;
      final double shippingFee = order.shippingFee;
      final double finalTotalBeforeVat = (subtotal + shippingFee - currentVoucherDiscount - finalCommission - seasonalDiscount).clamp(0, double.infinity);
      final double vatPercentage = policy.vatPercentage;
      final double vatAmount = finalTotalBeforeVat * (vatPercentage / 100);
      final double finalTotal = finalTotalBeforeVat + vatAmount;

      final double remainingDebt = finalTotal + agent.debtAmount;

      emit(state.copyWith(
        recalculatedCommissionDiscount: finalCommission,
        recalculatedSeasonalDiscount: seasonalDiscount,
        recalculatedVatPercentage: vatPercentage,
        recalculatedVatAmount: vatAmount,
        recalculatedFinalTotal: finalTotal,
        recalculatedRemainingDebt: remainingDebt,
        availableVouchers: availableVouchers,
      ));
    } catch (e) {
      developer.log("Error in _recalculateAndLoadVouchers: $e", name: "OrderDetailCubit");
    }
  }

  Future<void> _updateRecalculatedValues(OrderModel order) async {
    try {
      final agentResult = await _userProfileRepository.getUserProfile(order.userId);
      final agent = agentResult.fold((l) => null, (r) => r);
      if (agent == null) return;

      final policy = await _adminSettingsRepository.getDiscountPolicy();

      double commissionDiscount = 0.0;
      final isDiscountAllowed = await _checkIfPromotionAllowed(agent, isDiscount: true, policy: policy);
      final allowPromotionDuringCommitment = await _checkIfPromotionAllowedDuringCommitment(agent, policy: policy);

      bool shouldCalculateDiscount = isDiscountAllowed && order.items.isNotEmpty;
      if (agent.activeRewardProgram == 'sales_commitment' && !allowPromotionDuringCommitment) {
        shouldCalculateDiscount = false;
      }

      if (shouldCalculateDiscount) {
        try {
          final HttpsCallable callable = _functions.httpsCallable('calculateOrderDiscount');
          final itemsPayload = order.items.map((item) => {
            'productId': item.productId,
            'subtotal': item.price * item.quantityPerPackage * item.quantity,
          }).toList();
          final response = await callable.call({'items': itemsPayload, 'agentId': agent.id});
          commissionDiscount = (response.data['discount'] as num).toDouble();
        } catch (e) {
          developer.log("Error recalculating commission discount: $e", name: "OrderDetailCubit");
        }
      }

      double seasonalDiscount = 0.0;
      if (order.items.isNotEmpty) {
        final now = DateTime.now();
        bool isInPromoPeriod = true;
        if (policy.seasonalDiscountStart != null && now.isBefore(policy.seasonalDiscountStart!)) {
          isInPromoPeriod = false;
        }
        if (policy.seasonalDiscountEnd != null && now.isAfter(policy.seasonalDiscountEnd!)) {
          isInPromoPeriod = false;
        }
        if (policy.seasonalDiscountEnabled && isInPromoPeriod && (agent.activeRewardProgram != 'sales_commitment' || allowPromotionDuringCommitment)) {
          seasonalDiscount = order.subtotal * policy.seasonalDiscountRate;
        }
      }

      final isStackingAllowed = await _checkIfStackingAllowed(agent, policy: policy);
      double currentVoucherDiscount = state.voucherDiscount;
      double finalCommission = (state.appliedVoucher != null && !isStackingAllowed) ? 0.0 : commissionDiscount;

      final double subtotal = order.subtotal;
      final double shippingFee = order.shippingFee;
      final double finalTotalBeforeVat = (subtotal + shippingFee - currentVoucherDiscount - finalCommission - seasonalDiscount).clamp(0, double.infinity);
      final double vatPercentage = policy.vatPercentage;
      final double vatAmount = finalTotalBeforeVat * (vatPercentage / 100);
      final double finalTotal = finalTotalBeforeVat + vatAmount;

      final double remainingDebt = finalTotal + agent.debtAmount;

      emit(state.copyWith(
        recalculatedCommissionDiscount: finalCommission,
        recalculatedSeasonalDiscount: seasonalDiscount,
        recalculatedVatPercentage: vatPercentage,
        recalculatedVatAmount: vatAmount,
        recalculatedFinalTotal: finalTotal,
        recalculatedRemainingDebt: remainingDebt,
      ));
    } catch (e) {
      developer.log("Error in _updateRecalculatedValues: $e", name: "OrderDetailCubit");
    }
  }

  Future<bool> _checkIfStackingAllowed(UserModel agent, {required DiscountPolicyModel policy}) async {
    if (agent.allowVoucherStacking != null) {
      return agent.allowVoucherStacking!;
    }
    if (agent.salesRepId != null && agent.salesRepId!.isNotEmpty) {
      final salesRepResult = await _userProfileRepository.getUserProfile(agent.salesRepId!);
      final salesRep = salesRepResult.fold((l) => null, (r) => r);
      if (salesRep != null && salesRep.agentsAllowVoucherStacking != null) {
        return salesRep.agentsAllowVoucherStacking!;
      }
    }
    return policy.globalAllowVoucherStacking;
  }

  Future<bool> _checkIfPromotionAllowed(UserModel agent, {required bool isDiscount, required DiscountPolicyModel policy}) async {
    if (agent.customPromotionConfig != null) {
      final key = isDiscount ? 'allowDiscount' : 'allowVoucher';
      if (agent.customPromotionConfig![key] != null) {
        return agent.customPromotionConfig![key] as bool;
      }
    }
    if (agent.salesRepId != null && agent.salesRepId!.isNotEmpty) {
      final salesRepResult = await _userProfileRepository.getUserProfile(agent.salesRepId!);
      final salesRep = salesRepResult.fold((l) => null, (r) => r);
      if (salesRep != null && salesRep.agentsCustomPromotionConfig != null) {
        final key = isDiscount ? 'allowDiscount' : 'allowVoucher';
        if (salesRep.agentsCustomPromotionConfig![key] != null) {
          return salesRep.agentsCustomPromotionConfig![key] as bool;
        }
      }
    }
    final AgentPromotionConfig globalPromotion = (agent.role == 'agent_1') ? policy.agent1PromotionConfig : policy.agent2PromotionConfig;
    return isDiscount ? globalPromotion.allowDiscount : globalPromotion.allowVoucher;
  }

  Future<bool> _checkIfPromotionAllowedDuringCommitment(UserModel agent, {required DiscountPolicyModel policy}) async {
    if (agent.customPromotionConfig != null && agent.customPromotionConfig!['allowPromotionDuringCommitment'] != null) {
      return agent.customPromotionConfig!['allowPromotionDuringCommitment'] as bool;
    }
    if (agent.salesRepId != null && agent.salesRepId!.isNotEmpty) {
      final salesRepResult = await _userProfileRepository.getUserProfile(agent.salesRepId!);
      final salesRep = salesRepResult.fold((l) => null, (r) => r);
      if (salesRep != null && salesRep.agentsCustomPromotionConfig != null && salesRep.agentsCustomPromotionConfig!['allowPromotionDuringCommitment'] != null) {
        return salesRep.agentsCustomPromotionConfig!['allowPromotionDuringCommitment'] as bool;
      }
    }
    final AgentPromotionConfig globalPromotion = (agent.role == 'agent_1') ? policy.agent1PromotionConfig : policy.agent2PromotionConfig;
    return globalPromotion.allowPromotionDuringCommitment;
  }

  List<VoucherModel> _filterVouchers(List<OrderItemModel> items, UserModel user, bool allowPromotionDuringCommitment, List<VoucherModel> allActiveVouchers, Map<String, String> creatorRolesCache) {
    if (user.activeRewardProgram == 'sales_commitment' && !allowPromotionDuringCommitment) {
      return [];
    }

    final cartCategories = items.map((i) => i.productType ?? i.categoryId).toSet();
    final hasFoliar = cartCategories.contains('foliar_fertilizer');
    final hasRoot = cartCategories.contains('root_fertilizer');

    final totalFoliarQty = items
        .where((item) => (item.productType ?? item.categoryId) == 'foliar_fertilizer')
        .fold<int>(0, (sum, item) => sum + item.quantity);
    final totalRootQty = items
        .where((item) => (item.productType ?? item.categoryId) == 'root_fertilizer')
        .fold<int>(0, (sum, item) => sum + item.quantity);
    final totalQtyAll = items.fold<int>(0, (sum, item) => sum + item.quantity);

    final foliarSubtotal = items
        .where((item) => (item.productType ?? item.categoryId) == 'foliar_fertilizer')
        .fold<double>(0.0, (sum, item) => sum + (item.price * item.quantityPerPackage * item.quantity));
    final rootSubtotal = items
        .where((item) => (item.productType ?? item.categoryId) == 'root_fertilizer')
        .fold<double>(0.0, (sum, item) => sum + (item.price * item.quantityPerPackage * item.quantity));
    final totalSubtotal = items.fold<double>(0.0, (sum, item) => sum + (item.price * item.quantityPerPackage * item.quantity));

    return allActiveVouchers.where((v) {
      if (v.maxUses != 0 && v.usedCount >= v.maxUses) return false;
      
      double applicableSubtotal = totalSubtotal;
      int applicableQuantity = totalQtyAll;

      if (v.applicableCategory == 'foliar_fertilizer') {
        applicableSubtotal = foliarSubtotal;
        applicableQuantity = totalFoliarQty;
      } else if (v.applicableCategory == 'root_fertilizer') {
        applicableSubtotal = rootSubtotal;
        applicableQuantity = totalRootQty;
      }

      if (v.applicableCategory == 'foliar_fertilizer' && !hasFoliar) return false;
      if (v.applicableCategory == 'root_fertilizer' && !hasRoot) return false;

      if (applicableSubtotal < v.minOrderValue) return false;
      if (v.minQuantity != null && applicableQuantity < v.minQuantity!) return false;

      if (v.excludedUserIds.contains(user.id)) return false;
      if (user.salesRepId != null && v.excludedSalesRepIds.contains(user.salesRepId)) return false;

      final creatorRole = creatorRolesCache[v.createdBy];
      if (creatorRole == 'sales_rep' && user.salesRepId != v.createdBy) return false;

      bool isTargeted = false;
      switch (v.targetType) {
        case 'all':
          isTargeted = true;
          break;
        case 'agent_1':
          isTargeted = user.role == 'agent_1';
          break;
        case 'agent_2':
          isTargeted = user.role == 'agent_2';
          break;
        case 'specific_agents':
          isTargeted = v.targetUserIds.contains(user.id);
          break;
        case 'specific_sales_reps':
          isTargeted = user.salesRepId != null && v.targetSalesRepIds.contains(user.salesRepId);
          break;
        default:
          isTargeted = true;
      }
      if (!isTargeted) return false;

      return true;
    }).toList();
  }

  Future<void> applyVoucher(String code) async {
    if (code.isEmpty || state.order == null) return;
    if (state.order!.status != 'pending_approval') {
      emit(state.copyWith(status: OrderDetailStatus.voucherError, errorMessage: 'Không thể áp dụng voucher cho đơn hàng này.', clearError: false));
      emit(state.copyWith(status: OrderDetailStatus.success, clearError: true));
      return;
    }

    emit(state.copyWith(status: OrderDetailStatus.applyingVoucher));

    final authState = _authBloc.state;
    if (authState is! AuthAuthenticated) {
      emit(state.copyWith(status: OrderDetailStatus.error, errorMessage: 'Lỗi xác thực người dùng.'));
      return;
    }
    final userId = authState.user.id;
    final userRole = authState.user.role;
    final subtotal = state.order!.subtotal;

    final result = await _voucherRepository.applyVoucher(
      code: code.toUpperCase(),
      userId: userId,
      userRole: userRole,
      subtotal: subtotal,
      cartCategoryIds: state.order!.items.map((i) => i.productType ?? i.categoryId).toList(),
    );

    result.fold(
      (failure) {
        emit(state.copyWith(status: OrderDetailStatus.voucherError, errorMessage: failure.message, clearError: false));
        emit(state.copyWith(status: OrderDetailStatus.success, clearError: true));
      },
      (voucher) async {
        int applicableQuantity = state.order!.items.fold<int>(0, (sum, item) => sum + item.quantity);
        if (voucher.applicableCategory == 'foliar_fertilizer') {
          applicableQuantity = state.order!.items
              .where((item) => (item.productType ?? item.categoryId) == 'foliar_fertilizer')
              .fold<int>(0, (sum, item) => sum + item.quantity);
        } else if (voucher.applicableCategory == 'root_fertilizer') {
          applicableQuantity = state.order!.items
              .where((item) => (item.productType ?? item.categoryId) == 'root_fertilizer')
              .fold<int>(0, (sum, item) => sum + item.quantity);
        }

        if (voucher.minQuantity != null && applicableQuantity < voucher.minQuantity!) {
          emit(state.copyWith(
            status: OrderDetailStatus.voucherError,
            errorMessage: 'Số lượng sản phẩm áp dụng chưa đạt tối thiểu để dùng mã này (yêu cầu tối thiểu ${voucher.minQuantity} thùng).',
            clearError: false,
          ));
          emit(state.copyWith(status: OrderDetailStatus.success, clearError: true));
          return;
        }

        final discountAmount = _calculateVoucherDiscount(voucher, state.order!.items, subtotal);

        emit(state.copyWith(
          status: OrderDetailStatus.success,
          appliedVoucher: voucher,
          voucherDiscount: discountAmount,
        ));
        developer.log("Applied voucher ${voucher.id}, discount: $discountAmount", name: "OrderDetailCubit");
        
        await _updateRecalculatedValues(state.order!);
      },
    );
  }

  double _calculateVoucherDiscount(VoucherModel voucher, List<OrderItemModel> items, double subtotal) {
    double applicableSubtotal = subtotal;
    if (voucher.applicableCategory == 'foliar_fertilizer') {
      applicableSubtotal = items
          .where((item) => (item.productType ?? item.categoryId) == 'foliar_fertilizer')
          .fold<double>(0.0, (sum, item) => sum + item.subtotal);
    } else if (voucher.applicableCategory == 'root_fertilizer') {
      applicableSubtotal = items
          .where((item) => (item.productType ?? item.categoryId) == 'root_fertilizer')
          .fold<double>(0.0, (sum, item) => sum + item.subtotal);
    }

    int totalItemsInCases = 0;
    double totalCasesValue = 0;
    
    for (var item in items) {
      final category = item.productType ?? item.categoryId;
      if (voucher.applicableCategory == 'all' || category == voucher.applicableCategory) {
        if (item.quantityPerPackage > 1) {
          totalItemsInCases += item.quantity;
          totalCasesValue += (item.price * item.quantityPerPackage * item.quantity);
        }
      }
    }
    
    double averageCasePrice = totalItemsInCases > 0 
        ? (totalCasesValue / totalItemsInCases) 
        : 0.0;

    return voucher.calculateDiscount(
      applicableSubtotal, 
      totalItemsInCases: totalItemsInCases,
      averageCasePrice: averageCasePrice,
    );
  }

  void removeVoucher() {
    if (state.order?.status != 'pending_approval') return;

    emit(state.copyWith(
      status: OrderDetailStatus.success,
      forceVoucherToNull: true,
      voucherDiscount: 0.0,
    ));
    developer.log("Removed voucher", name: "OrderDetailCubit");
    
    if (state.order != null) {
      _updateRecalculatedValues(state.order!);
    }
  }

  Future<void> approveOrder({required double paidAmount}) async {
    if (state.order?.id == null) return;
    if (state.order!.status != 'pending_approval') return;

    emit(state.copyWith(status: OrderDetailStatus.updating));

    final voucherCode = state.appliedVoucher?.id;
    final voucherDiscount = state.voucherDiscount;

    final result = await _orderRepository.approveOrder(
      state.order!.id!,
      paidAmount: paidAmount,
      voucherDiscount: voucherDiscount,
      appliedVoucherCode: voucherCode,
      commissionDiscount: state.recalculatedCommissionDiscount,
      seasonalDiscount: state.recalculatedSeasonalDiscount,
      vatPercentage: state.recalculatedVatPercentage,
      vatAmount: state.recalculatedVatAmount,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: OrderDetailStatus.error, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(forceVoucherToNull: true, voucherDiscount: 0.0));
      },
    );
  }


  Future<void> rejectOrder(String reason) async {
    // ... (hàm này giữ nguyên) ...
    if (state.order?.id == null) return;
    // Chỉ cho phép từ chối khi đang chờ duyệt
    if (state.order!.status != 'pending_approval') return;

    emit(state.copyWith(status: OrderDetailStatus.updating));
    final result = await _orderRepository.rejectOrder(orderId: state.order!.id!, reason: reason);
    result.fold(
          (failure) => emit(state.copyWith(status: OrderDetailStatus.error, errorMessage: failure.message)),
          (_) {
        // Stream tự cập nhật, nhưng có thể reset voucher state ở đây nếu cần
        emit(state.copyWith(forceVoucherToNull: true, voucherDiscount: 0.0));
      },
    );
  }

  Future<void> notifyPaymentMade() async {
    // ... (hàm này giữ nguyên) ...
    if (state.order?.id == null) return;
    emit(state.copyWith(status: OrderDetailStatus.updatingPaymentStatus));
    final result = await _orderRepository.notifyPaymentMade(state.order!.id!);
    result.fold(
          (failure) => emit(state.copyWith(status: OrderDetailStatus.error, errorMessage: failure.message)),
          (_) { /* Stream tự cập nhật */ },
    );
  }

  void clearError() {
    emit(state.copyWith(status: OrderDetailStatus.success, clearError: true));
  }

  @override
  Future<void> close() {
    _orderSubscription?.cancel();
    _returnRequestSubscription?.cancel();
    return super.close();
  }
}