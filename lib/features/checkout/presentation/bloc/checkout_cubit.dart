import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
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
  StreamSubscription? _authSubscription;
  String _currentUserId = '';

  CheckoutCubit({
    required UserProfileRepository userProfileRepository,
    required OrderRepository orderRepository,
    required VoucherRepository voucherRepository,
    required AuthBloc authBloc,
    required CartCubit cartCubit,
  })  : _userProfileRepository = userProfileRepository,
        _orderRepository = orderRepository,
        _voucherRepository = voucherRepository,
        _authBloc = authBloc,
        _cartCubit = cartCubit,
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
          forceVoucherToNull: true, // Reset voucher khi tải lại trang
          discount: 0.0,
        ));
      },
    );
  }

  void selectAddress(AddressModel address) {
    emit(state.copyWith(status: CheckoutStatus.success, selectedAddress: address));
  }

  Future<void> applyVoucher(String code) async {
    if (code.isEmpty) return;

    emit(state.copyWith(status: CheckoutStatus.applyingVoucher));

    final result = await _voucherRepository.applyVoucher(code: code.toUpperCase(), userId: _currentUserId);

    result.fold(
            (failure) {
          emit(state.copyWith(status: CheckoutStatus.error, errorMessage: failure.message));
          // Sau khi báo lỗi, quay lại trạng thái success mà không có voucher
          emit(state.copyWith(status: CheckoutStatus.success));
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
      forceVoucherToNull: true, // Đặt cờ để xóa voucher
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
      paymentMethod: 'COD',
      status: 'pending',
    );

    final result = await _orderRepository.createOrder(order);

    result.fold(
          (failure) => emit(state.copyWith(status: CheckoutStatus.error, errorMessage: failure.message)),
          (orderId) {
        developer.log('CheckoutCubit: Order placed successfully with ID $orderId', name: 'CheckoutCubit');
        // Chỉ xóa giỏ hàng nếu đặt hàng từ giỏ hàng (không phải mua ngay)
        if (state.checkoutItems.length == _cartCubit.state.items.length) {
          _cartCubit.clearCart();
        }
        emit(state.copyWith(status: CheckoutStatus.orderSuccess));
      },
    );
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}