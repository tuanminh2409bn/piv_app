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
import 'package:piv_app/data/models/user_model.dart';

part 'checkout_state.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  final UserProfileRepository _userProfileRepository;
  final OrderRepository _orderRepository;
  final VoucherRepository _voucherRepository;
  final AuthBloc _authBloc;
  final CartCubit _cartCubit;
  final FirebaseFunctions _functions;

  StreamSubscription? _authSubscription;
  String _currentUserId = '';

  CheckoutCubit({
    required UserProfileRepository userProfileRepository,
    required OrderRepository orderRepository,
    required VoucherRepository voucherRepository,
    required AuthBloc authBloc,
    required CartCubit cartCubit,
    required FirebaseFunctions functions,
  })  : _userProfileRepository = userProfileRepository,
        _orderRepository = orderRepository,
        _voucherRepository = voucherRepository,
        _authBloc = authBloc,
        _cartCubit = cartCubit,
        _functions = functions,
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
    // --- SỬA LỖI: Tính toán giá trị cho OrderModel.total ---
    final double orderTotalBeforeCommission = (state.subtotal + state.shippingFee - state.discount).clamp(0, double.infinity);
    // Giá trị tiền hàng thực tế (sau cả commission)
    final double orderFinalTotal = state.finalTotal;
    // --------------------------------------------------

    const double paidAmountForThisOrder = 0.0; // Mặc định là 0 khi chờ duyệt
    // Công nợ còn lại dự kiến = Tiền hàng (finalTotal) + Nợ cũ - Tiền trả (là 0)
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
      discount: state.discount, // Voucher discount
      // --- SỬA LỖI: Gán đúng giá trị cho total và finalTotal ---
      total: orderTotalBeforeCommission,    // subtotal + ship - voucher
      finalTotal: orderFinalTotal,          // total - commissionDiscount
      // -------------------------------------------------------
      paymentMethod: 'bank_transfer',
      paymentStatus: 'unpaid',
      commissionDiscount: state.commissionDiscount,

      // --- LƯU THÔNG TIN CÔNG NỢ ĐÚNG ---
      debtAmount: currentAgentDebt,
      paidAmount: paidAmountForThisOrder, // = 0.0
      remainingDebt: remainingDebtAfterOrder,
      // ------------------------------------
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

    final remainingDebt = state.totalWithDebt - state.amountToPay;

    final order = OrderModel(
      userId: _currentUserId,
      items: state.checkoutItems.map((cartItem) => OrderItemModel.fromCartItem(cartItem)).toList(),
      shippingAddress: state.selectedAddress!,
      subtotal: state.subtotal,
      shippingFee: state.shippingFee,
      discount: state.discount,
      total: state.finalTotal,
      paymentMethod: state.paymentMethod,
      status: 'pending',
      commissionDiscount: state.commissionDiscount,
      finalTotal: state.totalWithDebt,
      salesRepId: authState.user.salesRepId,
      debtAmount: state.currentDebt,
      paidAmount: state.amountToPay,
      remainingDebt: remainingDebt,
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

  Future<void> loadCheckoutData({List<CartItemModel>? buyNowItems}) async {
    final authState = _authBloc.state;
    if (authState is! AuthAuthenticated) return;
    _currentUserId = authState.user.id;

    emit(state.copyWith(status: CheckoutStatus.loading));
    developer.log('CheckoutCubit: Loading checkout data...', name: 'CheckoutCubit');

    final user = authState.user;

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

    // LẤY CÔNG NỢ TỪ USER MODEL
    final currentDebt = user.debtAmount;

    final shouldCalculateDiscount = user.activeRewardProgram == 'instant_discount' && itemsToCheckout.isNotEmpty;

    // Tính toán tổng tiền ban đầu (sẽ được cập nhật sau khi có chiết khấu)
    final initialTotal = subtotal + shippingFee + currentDebt;

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
      currentDebt: currentDebt,      // <-- Gán công nợ
      amountToPay: initialTotal,     // <-- Mặc định cho người dùng trả hết
    ));

    if (shouldCalculateDiscount) {
      await calculateCommissionDiscount();
    } else {
      // Cập nhật lại amountToPay sau khi đã có finalTotal chính xác
      final finalTotal = state.subtotal - state.discount - state.commissionDiscount;
      final totalWithDebt = finalTotal + state.currentDebt;
      emit(state.copyWith(amountToPay: totalWithDebt.clamp(0, double.infinity)));
    }
  }

  Future<void> calculateCommissionDiscount() async {
    if (state.checkoutItems.isEmpty) return;

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

      // TÍNH TOÁN LẠI TỔNG TIỀN VÀ SỐ TIỀN CẦN TRẢ
      final newFinalTotal = state.subtotal - state.discount - discount;
      final newTotalWithDebt = newFinalTotal + state.currentDebt;

      emit(state.copyWith(
        status: CheckoutStatus.success,
        commissionDiscount: discount,
        amountToPay: newTotalWithDebt.clamp(0, double.infinity), // CẬP NHẬT LẠI SỐ TIỀN CẦN TRẢ
      ));
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
    );

    result.fold(
          (failure) {
        emit(state.copyWith(status: CheckoutStatus.error, errorMessage: failure.message, clearErrorMessage: false));
        emit(state.copyWith(status: CheckoutStatus.success, clearErrorMessage: true));
      },
          (voucher) {
        final discountAmount = voucher.calculateDiscount(state.subtotal);

        // TÍNH TOÁN LẠI TỔNG TIỀN VÀ SỐ TIỀN CẦN TRẢ
        final newFinalTotal = state.subtotal - discountAmount - state.commissionDiscount;
        final newTotalWithDebt = newFinalTotal + state.currentDebt;

        emit(state.copyWith(
          status: CheckoutStatus.success,
          appliedVoucher: voucher,
          discount: discountAmount,
          amountToPay: newTotalWithDebt.clamp(0, double.infinity), // CẬP NHẬT LẠI SỐ TIỀN CẦN TRẢ
        ));
      },
    );
  }

  void removeVoucher() {
    // TÍNH TOÁN LẠI TỔNG TIỀN VÀ SỐ TIỀN CẦN TRẢ
    final newFinalTotal = state.subtotal - 0 - state.commissionDiscount; // Bỏ voucher
    final newTotalWithDebt = newFinalTotal + state.currentDebt;

    emit(state.copyWith(
      status: CheckoutStatus.success,
      forceVoucherToNull: true,
      discount: 0.0,
      amountToPay: newTotalWithDebt.clamp(0, double.infinity), // CẬP NHẬT LẠI SỐ TIỀN CẦN TRẢ
    ));
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
      amountToPay: initialTotal.clamp(0, double.infinity),
      forceVoucherToNull: true,
    ));
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
    emit(state.copyWith(
      checkoutItems: items,
      subtotal: subtotal,
    ));
    if (items.isNotEmpty) {
      calculateCommissionDiscount();
    } else {
      emit(state.copyWith(commissionDiscount: 0.0));
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