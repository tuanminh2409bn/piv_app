import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:equatable/equatable.dart';
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
        super(const CheckoutState());

  Future<void> loadCheckoutData({List<CartItemModel>? buyNowItems}) async {
    final authState = _authBloc.state;
    if (authState is! AuthAuthenticated) return;
    _currentUserId = authState.user.id;

    emit(state.copyWith(status: CheckoutStatus.loading));
    developer.log('CheckoutCubit: Loading checkout data...', name: 'CheckoutCubit');

    final result = await _userProfileRepository.getUserProfile(_currentUserId);

    result.fold(
          (failure) => emit(state.copyWith(status: CheckoutStatus.error, errorMessage: failure.message)),
          (user) {
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

        emit(state.copyWith(
          status: CheckoutStatus.success,
          addresses: addresses,
          selectedAddress: defaultAddress,
          checkoutItems: itemsToCheckout,
          subtotal: subtotal,
          shippingFee: shippingFee,
          forceVoucherToNull: true,
          discount: 0.0,
          commissionDiscount: 0.0,
        ));

        if (itemsToCheckout.isNotEmpty) {
          calculateCommissionDiscount();
        }
      },
    );
  }

  Future<void> calculateCommissionDiscount() async {
    if (state.checkoutItems.isEmpty) return;

    emit(state.copyWith(status: CheckoutStatus.calculatingDiscount));
    try {
      final HttpsCallable callable = _functions.httpsCallable('calculateOrderDiscount');

      // <<< SỬA ĐỔI PAYLOAD GỬI LÊN Ở ĐÂY >>>
      final itemsPayload = state.checkoutItems.map((item) => {
        'productId': item.productId,
        'subtotal': item.subtotal, // Gửi tổng giá trị đã tính đúng
      }).toList();
      // <<< HẾT PHẦN SỬA ĐỔI >>>

      final response = await callable.call({'items': itemsPayload});
      final discount = (response.data['discount'] as num).toDouble();

      developer.log('>>> KẾT QUẢ CHIẾT KHẤU TỪ BACKEND: $discount', name: 'CheckoutDebug');

      emit(state.copyWith(
        status: CheckoutStatus.success,
        commissionDiscount: discount,
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

  Future<void> applyVoucher(String code) async {
    if (code.isEmpty) return;
    emit(state.copyWith(status: CheckoutStatus.applyingVoucher));
    final result = await _voucherRepository.applyVoucher(code: code.toUpperCase(), userId: _currentUserId);
    result.fold(
            (failure) {
          emit(state.copyWith(status: CheckoutStatus.error, errorMessage: failure.message, clearErrorMessage: false));
          emit(state.copyWith(status: CheckoutStatus.success, clearErrorMessage: true));
        },
            (voucher) {
          final discountAmount = voucher.calculateDiscount(state.subtotal);
          emit(state.copyWith(
            status: CheckoutStatus.success,
            appliedVoucher: voucher,
            discount: discountAmount,
          ));
        }
    );
  }

  void removeVoucher() {
    emit(state.copyWith(
      status: CheckoutStatus.success,
      forceVoucherToNull: true,
      discount: 0.0,
    ));
  }

  Future<void> placeOrder() async {
    if (state.selectedAddress == null || state.checkoutItems.isEmpty || _currentUserId.isEmpty) {
      emit(state.copyWith(status: CheckoutStatus.error, errorMessage: "Vui lòng chọn địa chỉ và sản phẩm."));
      return;
    }

    emit(state.copyWith(status: CheckoutStatus.placingOrder));

    final order = OrderModel(
      userId: _currentUserId,
      items: state.checkoutItems.map((cartItem) => OrderItemModel.fromCartItem(cartItem)).toList(),
      shippingAddress: state.selectedAddress!,
      subtotal: state.subtotal,
      shippingFee: state.shippingFee,
      discount: state.discount,
      total: state.total,
      paymentMethod: state.paymentMethod,
      status: 'pending',
      commissionDiscount: state.commissionDiscount,
      finalTotal: state.finalTotal,
    );

    final result = await _orderRepository.createOrder(order);

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

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}