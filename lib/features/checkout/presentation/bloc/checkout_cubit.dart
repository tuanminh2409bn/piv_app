// lib/features/checkout/presentation/bloc/checkout_cubit.dart

import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:equatable/equatable.dart';
import 'package:collection/collection.dart';
import 'package:piv_app/data/models/address_model.dart';
import 'package:piv_app/data/models/cart_item_model.dart';
import 'package:piv_app/data/models/order_item_model.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';
import 'package:piv_app/features/vouchers/domain/repositories/voucher_repository.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_settings_repository.dart'; // <<< THÊM MỚI
import 'package:piv_app/data/models/user_model.dart';

part 'checkout_state.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  final UserProfileRepository _userProfileRepository;
  final OrderRepository _orderRepository;
  final VoucherRepository _voucherRepository;
  final AuthBloc _authBloc;
  final CartCubit _cartCubit;
  final FirebaseFunctions _functions;
  final AdminSettingsRepository _adminSettingsRepository; // <<< THÊM MỚI

  StreamSubscription? _authSubscription;
  String _currentUserId = '';
  List<VoucherModel> _allActiveVouchers = [];

  List<VoucherModel> _filterVouchers(List<CartItemModel> items) {
    final cartCategories = items.map((i) => i.categoryId).toSet();
    final hasFoliar = cartCategories.contains('foliar_fertilizer');
    final hasRoot = cartCategories.contains('root_fertilizer');

    return _allActiveVouchers.where((v) {
      if (v.maxUses != 0 && v.usedCount >= v.maxUses) return false;
      if (v.applicableCategory == 'all') return true;
      if (v.applicableCategory == 'foliar_fertilizer' && hasFoliar) return true;
      if (v.applicableCategory == 'root_fertilizer' && hasRoot) return true;
      return false;
    }).toList();
  }

  CheckoutCubit({
    required UserProfileRepository userProfileRepository,
    required OrderRepository orderRepository,
    required VoucherRepository voucherRepository,
    required AuthBloc authBloc,
    required CartCubit cartCubit,
    required FirebaseFunctions functions,
    required AdminSettingsRepository adminSettingsRepository, // <<< THÊM MỚI
  })  : _userProfileRepository = userProfileRepository,
        _orderRepository = orderRepository,
        _voucherRepository = voucherRepository,
        _authBloc = authBloc,
        _cartCubit = cartCubit,
        _functions = functions,
        _adminSettingsRepository = adminSettingsRepository, // <<< THÊM MỚI
        super(const CheckoutState()) {
    _authSubscription = _authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        // Chỉ cập nhật địa chỉ nếu là lần đầu hoặc người dùng thay đổi
        if (state.status == CheckoutStatus.initial || _currentUserId != authState.user.id) {
          _updateAddressesFromAuth(authState.user);
        }
      }
    });
  }

  void _updateAddressesFromAuth(UserModel user) {
    if (state.status != CheckoutStatus.initial && user.id != _currentUserId) return;

    final newAddresses = user.addresses;
    // --- THAY ĐỔI: Sửa tên class và đảm bảo import ---
    if (const DeepCollectionEquality().equals(newAddresses, state.addresses)) {
      return;
    }

    developer.log('CheckoutCubit: Detected address change from AuthBloc. Updating addresses.', name: 'CheckoutCubit');

    AddressModel? newSelectedAddress = state.selectedAddress;
    if (newSelectedAddress != null && !newAddresses.any((a) => a.id == newSelectedAddress!.id)) {
      newSelectedAddress = null;
    }

    if (newSelectedAddress == null && newAddresses.isNotEmpty) {
      try {
        newSelectedAddress = newAddresses.firstWhere((a) => a.isDefault);
      } catch (e) {
        newSelectedAddress = newAddresses.first;
      }
    }

    emit(state.copyWith(
      addresses: newAddresses,
      selectedAddress: newSelectedAddress,
    ));
  }

  Future<void> placeOrderOnBehalfOf() async {
    if (state.selectedAddress == null ||
        state.checkoutItems.isEmpty ||
        state.placeOrderForAgent == null) {
      emit(state.copyWith(
          status: CheckoutStatus.error,
          errorMessage: "Vui lòng chọn địa chỉ và thêm sản phẩm."));
      return;
    }

    emit(state.copyWith(status: CheckoutStatus.placingOrder));

    final authState = _authBloc.state;
    if (authState is! AuthAuthenticated) {
      emit(state.copyWith(
          status: CheckoutStatus.error, errorMessage: "Lỗi xác thực người dùng đặt hộ."));
      return;
    }

    final agent = state.placeOrderForAgent!;
    final currentAgentDebt = state.currentDebt;
    final double orderTotalBeforeCommission = (state.subtotal + state.shippingFee - state.discount).clamp(0, double.infinity);
    final double orderFinalTotal = state.finalTotal;
    const double paidAmountForThisOrder = 0.0;
    final double remainingDebtAfterOrder = orderFinalTotal + currentAgentDebt - paidAmountForThisOrder;

    final order = OrderModel(
      userId: agent.id,
      status: 'pending_approval',
      placedBy: PlacedByInfo(
        userId: authState.user.id,
        role: authState.user.role,
      ),
      salesRepId: agent.salesRepId,
      items: state.checkoutItems
          .map((cartItem) => OrderItemModel.fromCartItem(cartItem))
          .toList(),
      shippingAddress: state.selectedAddress!,
      subtotal: state.subtotal,
      shippingFee: state.shippingFee,
      discount: state.discount,
      total: orderTotalBeforeCommission,
      finalTotal: orderFinalTotal,
      paymentMethod: 'bank_transfer',
      paymentStatus: 'unpaid',
      commissionDiscount: state.commissionDiscount,
      debtAmount: currentAgentDebt,
      paidAmount: paidAmountForThisOrder,
      remainingDebt: remainingDebtAfterOrder,
      appliedVoucherCode: state.appliedVoucher?.id,
      vatPercentage: state.vatPercentage,
      vatAmount: state.vatAmount,
      legalInfo: CustomerLegalInfo(
        displayName: agent.displayName,
        idCardOrTaxId: agent.idCardOrTaxId,
        phoneNumber: agent.phoneNumber,
        currentAddress: agent.currentAddress,
      ),
    );

    final result = await _orderRepository.createOrder(
      order,
      clearCart: false,
    );

    result.fold(
          (failure) => emit(state.copyWith(
          status: CheckoutStatus.error, errorMessage: failure.message)),
          (orderId) {
        emit(state.copyWith(
            status: CheckoutStatus.orderSuccess, newOrderId: orderId));
      },
    );
  }

  Future<void> placeOrder() async {
    if (state.selectedAddress == null || (state.checkoutItems.isEmpty && state.currentDebt <= 0)) {
      emit(state.copyWith(status: CheckoutStatus.error, errorMessage: "Vui lòng chọn địa chỉ và sản phẩm, hoặc có công nợ để thanh toán."));
      return;
    }

    if (state.amountToPay < 0) {
      emit(state.copyWith(status: CheckoutStatus.error, errorMessage: "Số tiền thanh toán không thể là số âm."));
      return;
    }

    emit(state.copyWith(status: CheckoutStatus.placingOrder));

    final authState = _authBloc.state;
    if (authState is! AuthAuthenticated) {
      emit(state.copyWith(status: CheckoutStatus.error, errorMessage: "Lỗi xác thực người dùng."));
      return;
    }

    final double orderTotalBeforeCommission = (state.subtotal + state.shippingFee - state.discount).clamp(0, double.infinity);
    final remainingDebt = state.totalWithDebt - state.amountToPay;

    final order = OrderModel(
      userId: _currentUserId,
      items: state.checkoutItems.map((cartItem) => OrderItemModel.fromCartItem(cartItem)).toList(),
      shippingAddress: state.selectedAddress!,
      subtotal: state.subtotal,
      shippingFee: state.shippingFee,
      discount: state.discount,
      total: orderTotalBeforeCommission,
      paymentMethod: state.paymentMethod,
      status: 'pending',
      commissionDiscount: state.commissionDiscount,
      finalTotal: state.finalTotal,
      salesRepId: authState.user.salesRepId,
      debtAmount: state.currentDebt,
      paidAmount: state.amountToPay,
      remainingDebt: remainingDebt,
      appliedVoucherCode: state.appliedVoucher?.id,
      vatPercentage: state.vatPercentage,
      vatAmount: state.vatAmount,
      legalInfo: CustomerLegalInfo(
        displayName: authState.user.displayName,
        idCardOrTaxId: authState.user.idCardOrTaxId,
        phoneNumber: authState.user.phoneNumber,
        currentAddress: authState.user.currentAddress,
      ),
    );

    final result = await _orderRepository.createOrder(
      order,
      clearCart: true,
    );

    result.fold(
          (failure) => emit(state.copyWith(status: CheckoutStatus.error, errorMessage: failure.message)),
          (orderId) {
        developer.log('CheckoutCubit: Order placed successfully with ID $orderId', name: 'CheckoutCubit');
        if (state.checkoutItems.length == _cartCubit.state.items.length) {
          _cartCubit.clearCart();
        }
        emit(state.copyWith(status: CheckoutStatus.orderSuccess, newOrderId: orderId));
      },
    );
  }

  Future<bool> _checkIfStackingAllowed(UserModel agent) async {
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

    final policy = await _adminSettingsRepository.getDiscountPolicy();
    return policy.globalAllowVoucherStacking;
  }

  Future<void> loadCheckoutData({List<CartItemModel>? buyNowItems}) async {
    final authState = _authBloc.state;
    if (authState is! AuthAuthenticated) return;
    _currentUserId = authState.user.id;

    emit(state.copyWith(status: CheckoutStatus.loading));
    developer.log('CheckoutCubit: Loading checkout data...', name: 'CheckoutCubit');

    // LẤY THÔNG TIN NGƯỜI DÙNG MỚI NHẤT TỪ FIREBASE THAY VÌ DÙNG AUTHBLOC (VỐN CÓ THỂ BỊ CŨ)
    final userProfileResult = await _userProfileRepository.getUserProfile(_currentUserId);
    final user = userProfileResult.getOrElse(() => authState.user);

    final addresses = user.addresses;
    AddressModel? defaultAddress;
    if (addresses.isNotEmpty) {
      try {
        defaultAddress = addresses.firstWhere((a) => a.isDefault);
      } catch (e) {
        defaultAddress = addresses.first;
      }
    }

    final itemsToCheckout = buyNowItems ?? _cartCubit.state.items;
    final subtotal = itemsToCheckout.fold<double>(0.0, (sum, item) => sum + item.subtotal);
    const shippingFee = 0.0;

    // LẤY CÔNG NỢ TỪ USER MODEL MỚI NHẤT
    final currentDebt = user.debtAmount;

    // --- TẢI DANH SÁCH VOUCHER KHẢ DỤNG ---
    final voucherResult = await _voucherRepository.getActiveVouchers();
    _allActiveVouchers = voucherResult.getOrElse(() => []);
    final availableVouchers = _filterVouchers(itemsToCheckout);
    developer.log('CheckoutCubit: Loaded ${_allActiveVouchers.length} active vouchers, ${availableVouchers.length} available', name: 'CheckoutCubit');
    // --------------------------------------

    // --- TẢI CẤU HÌNH VAT ---
    double vatPercentage = 10.0;
    try {
      final policy = await _adminSettingsRepository.getDiscountPolicy();
      vatPercentage = policy.vatPercentage;
    } catch (e) {
      developer.log("Error loading VAT: $e", name: "CheckoutCubit");
    }
    // ------------------------

    final shouldCalculateDiscount = user.activeRewardProgram == 'instant_discount' && itemsToCheckout.isNotEmpty;

    // Tính toán tổng tiền ban đầu (sẽ được cập nhật sau khi có chiết khấu)
    final initialTotal = subtotal + shippingFee + currentDebt;
    
    // Lưu ý: VAT sẽ được get trong State thông qua getter finalTotal và totalWithDebt.
    // Chúng ta chỉ cần truyền vatPercentage vào state.

    emit(state.copyWith(
      status: shouldCalculateDiscount ? CheckoutStatus.calculatingDiscount : CheckoutStatus.success,
      addresses: addresses,
      selectedAddress: defaultAddress,
      checkoutItems: itemsToCheckout,
      subtotal: subtotal,
      shippingFee: shippingFee,
      forceVoucherToNull: true,
      discount: 0.0,
      commissionDiscount: 0.0,
      currentDebt: currentDebt,      
      availableVouchers: availableVouchers, // <<< CẬP NHẬT
      vatPercentage: vatPercentage,
    ));

    if (shouldCalculateDiscount) {
      await calculateCommissionDiscount();
    } else {
      // Cập nhật lại amountToPay sau khi đã có finalTotal chính xác (gồm VAT)
      emit(state.copyWith(amountToPay: state.totalWithDebt.clamp(0, double.infinity)));
    }
  }

  Future<void> calculateCommissionDiscount() async {
    if (state.checkoutItems.isEmpty) return;

    // Không tính chiết khấu đại lý nếu đã có voucher được áp dụng
    if (state.appliedVoucher != null) {
      if (state.commissionDiscount != 0.0) {
        emit(state.copyWith(commissionDiscount: 0.0));
      }
      return;
    }

    emit(state.copyWith(status: CheckoutStatus.calculatingDiscount));
    try {
      final HttpsCallable callable = _functions.httpsCallable('calculateOrderDiscount');
      final itemsPayload = state.checkoutItems.map((item) => {
        'productId': item.productId,
        'subtotal': item.subtotal,
      }).toList();
      final Map<String, dynamic> payload = {'items': itemsPayload};
      if (state.placeOrderForAgent != null) {
        payload['agentId'] = state.placeOrderForAgent!.id;
      }

      final response = await callable.call(payload);
      final discount = (response.data['discount'] as num).toDouble();

      final newState = state.copyWith(
        status: CheckoutStatus.success,
        commissionDiscount: discount,
      );
      emit(newState.copyWith(amountToPay: newState.totalWithDebt.clamp(0, double.infinity)));
    } catch (e) {
      developer.log("Error calculating discount: $e", name: "CheckoutCubit");
      emit(state.copyWith(
        status: CheckoutStatus.success,
        errorMessage: "Không thể tính chiết khấu tự động.",
      ));
    }
  }

  void selectAddress(AddressModel address) {
    emit(state.copyWith(status: CheckoutStatus.success, selectedAddress: address));
  }

  void selectPaymentMethod(String method) {
    emit(state.copyWith(paymentMethod: method));
  }

  void startOrderOnBehalfOf(String agentId) {
    emit(state.copyWith(placeOrderForUserId: agentId));
    loadCheckoutData();
  }

  Future<void> applyVoucher(String code) async {
    if (code.isEmpty) return;
    emit(state.copyWith(status: CheckoutStatus.applyingVoucher));

    final authState = _authBloc.state;
    if (authState is! AuthAuthenticated) {
      emit(state.copyWith(status: CheckoutStatus.error, errorMessage: 'Lỗi xác thực người dùng.'));
      return;
    }
    final userRole = authState.user.role;

    final result = await _voucherRepository.applyVoucher(
      code: code.toUpperCase(),
      userId: _currentUserId,
      userRole: userRole,
      subtotal: state.subtotal,
      cartCategoryIds: state.checkoutItems.map((i) => i.categoryId).toList(),
    );

    result.fold(
          (failure) {
        emit(state.copyWith(status: CheckoutStatus.error, errorMessage: failure.message, clearErrorMessage: false));
        emit(state.copyWith(status: CheckoutStatus.success, clearErrorMessage: true));
      },
          (voucher) {
        // --- TÍNH TOÁN THÔNG TIN THÙNG ĐỂ ÁP DỤNG MUA X TẶNG Y ---
        int totalItemsInCases = 0;
        double totalCasesValue = 0;
        
        for (var item in state.checkoutItems) {
          if (item.quantityPerPackage > 1) {
            totalItemsInCases += item.quantity;
            totalCasesValue += item.subtotal;
          }
        }
        
        double averageCasePrice = totalItemsInCases > 0 
            ? (totalCasesValue / totalItemsInCases) 
            : 0.0;

        final discountAmount = voucher.calculateDiscount(
          state.subtotal, 
          totalItemsInCases: totalItemsInCases,
          averageCasePrice: averageCasePrice,
        );
        // --- KẾT THÚC TÍNH TOÁN ---

        final newState = state.copyWith(
          status: CheckoutStatus.success,
          appliedVoucher: voucher,
          discount: discountAmount,
        );
        emit(newState.copyWith(amountToPay: newState.totalWithDebt.clamp(0, double.infinity)));
      },
    );
  }

  void selectVoucher(VoucherModel voucher) {
    // --- TÍNH TOÁN THÔNG TIN THÙNG ĐỂ ÁP DỤNG MUA X TẶNG Y ---
    int totalItemsInCases = 0;
    double totalCasesValue = 0;
    
    for (var item in state.checkoutItems) {
      if (item.quantityPerPackage > 1) {
        totalItemsInCases += item.quantity;
        totalCasesValue += item.subtotal;
      }
    }
    
    double averageCasePrice = totalItemsInCases > 0 
        ? (totalCasesValue / totalItemsInCases) 
        : 0.0;

    final discountAmount = voucher.calculateDiscount(
      state.subtotal, 
      totalItemsInCases: totalItemsInCases,
      averageCasePrice: averageCasePrice,
    );
    // --- KẾT THÚC TÍNH TOÁN ---

    final newState = state.copyWith(
      status: CheckoutStatus.success,
      appliedVoucher: voucher,
      discount: discountAmount,
      commissionDiscount: state.isStackingAllowed ? state.commissionDiscount : 0.0,
    );
    emit(newState.copyWith(amountToPay: newState.totalWithDebt.clamp(0, double.infinity)));
  }

  void removeVoucher() {
    emit(state.copyWith(
      status: CheckoutStatus.success,
      forceVoucherToNull: true,
      discount: 0.0,
    ));
    
    // Tính toán lại chiết khấu đại lý và tổng tiền sau khi bỏ voucher
    calculateCommissionDiscount();
  }

  Future<void> loadCheckoutDataForAgent(UserModel agent) async {
    emit(state.copyWith(status: CheckoutStatus.loading));
    final agentProfileResult = await _userProfileRepository.getUserProfile(agent.id);
    if (agentProfileResult.isLeft()) {
      emit(state.copyWith(status: CheckoutStatus.error, errorMessage: 'Không thể tải thông tin chi tiết của đại lý.'));
      return;
    }
    final UserModel agentWithDetails = agentProfileResult.getOrElse(() => agent);

    AddressModel? defaultAddress;
    if (agentWithDetails.addresses.isNotEmpty) {
      try {
        defaultAddress = agentWithDetails.addresses.firstWhere((a) => a.isDefault);
      } catch (e) {
        defaultAddress = agentWithDetails.addresses.first;
      }
    }

    final currentDebt = agentWithDetails.debtAmount;
    final initialTotal = currentDebt; // Chỉ có công nợ ban đầu

    // --- TẢI DANH SÁCH VOUCHER KHẢ DỤNG ---
    final voucherResult = await _voucherRepository.getActiveVouchers();
    _allActiveVouchers = voucherResult.getOrElse(() => []);
    // Vì checkoutItems rỗng ban đầu nên availableVouchers có thể sẽ khác sau khi thêm item
    final availableVouchers = _filterVouchers([]);
    // --------------------------------------

    // --- TẢI CẤU HÌNH VAT VÀ CỘNG DỒN CHIẾT KHẤU ---
    double vatPercentage = 10.0;
    bool isStackingAllowed = false;
    try {
      final policy = await _adminSettingsRepository.getDiscountPolicy();
      vatPercentage = policy.vatPercentage;
      isStackingAllowed = await _checkIfStackingAllowed(agentWithDetails);
    } catch (e) {
      developer.log("Error loading config: $e", name: "CheckoutCubit");
    }
    // ------------------------

    emit(state.copyWith(
      status: CheckoutStatus.success,
      addresses: agentWithDetails.addresses,
      selectedAddress: defaultAddress,
      placeOrderForAgent: agentWithDetails,
      placeOrderForUserId: agentWithDetails.id,
      checkoutItems: [],
      subtotal: 0.0,
      shippingFee: 0.0,
      discount: 0.0,
      commissionDiscount: 0.0,
      currentDebt: currentDebt, // <-- Đã lấy đúng công nợ
      forceVoucherToNull: true,
      availableVouchers: availableVouchers,
      vatPercentage: vatPercentage,
      isStackingAllowed: isStackingAllowed,
    ));
    
    // Khởi tạo amountToPay sau khi state có VAT
    emit(state.copyWith(amountToPay: state.totalWithDebt.clamp(0, double.infinity)));
  }

  void addItemToOnBehalfCart(CartItemModel newItem) {
    final currentItems = List<CartItemModel>.from(state.checkoutItems);
    final existingIndex = currentItems.indexWhere(
            (item) => item.productId == newItem.productId && item.caseUnitName == newItem.caseUnitName
    );

    if (existingIndex != -1) {
      final updatedItem = currentItems[existingIndex].copyWith(
          quantity: currentItems[existingIndex].quantity + newItem.quantity
      );
      currentItems[existingIndex] = updatedItem;
    } else {
      currentItems.add(newItem);
    }
    _recalculateTotalsAndEmit(currentItems);
  }

  void updateItemQuantityInOnBehalfCart(String productId, String caseUnitName, int newQuantity) {
    final currentItems = List<CartItemModel>.from(state.checkoutItems);
    final index = currentItems.indexWhere(
            (item) => item.productId == productId && item.caseUnitName == caseUnitName
    );

    if (index != -1) {
      if (newQuantity > 0) {
        currentItems[index] = currentItems[index].copyWith(quantity: newQuantity);
      } else {
        currentItems.removeAt(index);
      }
      _recalculateTotalsAndEmit(currentItems);
    }
  }

  void removeItemFromOnBehalfCart(String productId, String caseUnitName) {
    final currentItems = List<CartItemModel>.from(state.checkoutItems);
    currentItems.removeWhere(
            (item) => item.productId == productId && item.caseUnitName == caseUnitName
    );
    _recalculateTotalsAndEmit(currentItems);
  }


  void _recalculateTotalsAndEmit(List<CartItemModel> items) {
    final subtotal = items.fold<double>(0.0, (sum, item) => sum + item.subtotal);
    
    // Tính toán lại vouchers dựa trên items mới
    final updatedAvailableVouchers = _filterVouchers(items);
    
    // Kiểm tra xem voucher đang áp dụng có còn hợp lệ không
    VoucherModel? newAppliedVoucher = state.appliedVoucher;
    bool forceVoucherToNull = false;
    double newDiscount = state.discount;
    
    if (newAppliedVoucher != null) {
      // Nếu voucher đang áp dụng không còn trong danh sách hợp lệ, hoặc không đủ điều kiện minOrderValue, thì bỏ áp dụng
      final stillValid = updatedAvailableVouchers.any((v) => v.id == newAppliedVoucher!.id) 
                         && subtotal >= newAppliedVoucher.minOrderValue;
      if (!stillValid) {
        newAppliedVoucher = null;
        forceVoucherToNull = true;
        newDiscount = 0.0;
      } else {
        // Cập nhật lại số tiền giảm nếu voucher vẫn hợp lệ
        // Tính theo subtotal mới
        // (Lưu ý: hàm applyVoucher đang set discount. Ở đây ta cần update)
        // Đây là fallback, thông thường nên removeVoucher rồi bắt người dùng chọn lại cho an toàn.
        newAppliedVoucher = null;
        forceVoucherToNull = true;
        newDiscount = 0.0;
      }
    }

    emit(state.copyWith(
      checkoutItems: items,
      subtotal: subtotal,
      availableVouchers: updatedAvailableVouchers,
      appliedVoucher: newAppliedVoucher,
      forceVoucherToNull: forceVoucherToNull,
      discount: newDiscount,
    ));

    if (items.isNotEmpty) {
      calculateCommissionDiscount();
    } else {
      emit(state.copyWith(commissionDiscount: 0.0));
      // Cập nhật lại total
      emit(state.copyWith(amountToPay: state.totalWithDebt.clamp(0, double.infinity)));
    }
  }

  void updateAmountToPay(double amount) {
    // Chỉ emit khi giá trị thực sự thay đổi để tránh vòng lặp vô tận với listener
    if (state.amountToPay != amount) {
      emit(state.copyWith(amountToPay: amount));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}