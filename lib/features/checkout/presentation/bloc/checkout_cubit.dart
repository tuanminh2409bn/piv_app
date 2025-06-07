import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/address_model.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/data/models/order_item_model.dart';
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/cart/presentation/bloc/cart_cubit.dart';
import 'dart:async';
import 'dart:developer' as developer;

part 'checkout_state.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  final UserProfileRepository _userProfileRepository;
  final OrderRepository _orderRepository;
  final AuthBloc _authBloc;
  final CartCubit _cartCubit;
  StreamSubscription? _authSubscription;
  String _currentUserId = '';

  CheckoutCubit({
    required UserProfileRepository userProfileRepository,
    required OrderRepository orderRepository,
    required AuthBloc authBloc,
    required CartCubit cartCubit,
  })  : _userProfileRepository = userProfileRepository,
        _orderRepository = orderRepository,
        _authBloc = authBloc,
        _cartCubit = cartCubit,
        super(const CheckoutState()) {

    // Lắng nghe trạng thái AuthBloc để biết userId
    _authSubscription = _authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        _currentUserId = authState.user.id;
        loadCheckoutData(); // Tải dữ liệu khi người dùng đăng nhập
      } else {
        _currentUserId = '';
        emit(const CheckoutState()); // Reset state khi đăng xuất
      }
    });

    // Tải dữ liệu lần đầu nếu người dùng đã đăng nhập sẵn
    final initialAuthState = _authBloc.state;
    if (initialAuthState is AuthAuthenticated) {
      _currentUserId = initialAuthState.user.id;
      loadCheckoutData();
    }
  }

  /// Tải dữ liệu cần thiết cho trang checkout, chủ yếu là địa chỉ người dùng
  Future<void> loadCheckoutData() async {
    if (_currentUserId.isEmpty) return;

    emit(state.copyWith(status: CheckoutStatus.loading));
    developer.log('CheckoutCubit: Loading checkout data (addresses)...', name: 'CheckoutCubit');

    final result = await _userProfileRepository.getUserProfile(_currentUserId);

    result.fold(
            (failure) {
          emit(state.copyWith(status: CheckoutStatus.error, errorMessage: failure.message));
        },
            (user) {
          // Sau khi lấy được user, chúng ta có danh sách địa chỉ của họ
          final addresses = user.addresses;
          AddressModel? defaultAddress;
          if (addresses.isNotEmpty) {
            try {
              // Tìm địa chỉ mặc định
              defaultAddress = addresses.firstWhere((a) => a.isDefault);
            } catch (e) {
              // Nếu không có địa chỉ nào là default, chọn cái đầu tiên
              defaultAddress = addresses.first;
            }
          }

          emit(state.copyWith(
            status: CheckoutStatus.success,
            addresses: addresses,
            selectedAddress: defaultAddress,
          ));
          developer.log('CheckoutCubit: addresses loaded, default selected: ${defaultAddress?.street}', name: 'CheckoutCubit');
        }
    );
  }

  /// Cho phép người dùng chọn một địa chỉ khác từ danh sách
  void selectAddress(AddressModel address) {
    emit(state.copyWith(status: CheckoutStatus.success, selectedAddress: address));
  }

  /// Xử lý logic đặt hàng
  Future<void> placeOrder() async {
    // Kiểm tra các điều kiện cần thiết
    final cartState = _cartCubit.state;
    if (state.selectedAddress == null) {
      emit(state.copyWith(status: CheckoutStatus.error, errorMessage: "Vui lòng chọn địa chỉ giao hàng."));
      return;
    }
    if (cartState.items.isEmpty) {
      emit(state.copyWith(status: CheckoutStatus.error, errorMessage: "Giỏ hàng của bạn đang trống."));
      return;
    }
    if (_currentUserId.isEmpty) {
      emit(state.copyWith(status: CheckoutStatus.error, errorMessage: "Lỗi xác thực người dùng."));
      return;
    }

    emit(state.copyWith(status: CheckoutStatus.placingOrder));
    developer.log('CheckoutCubit: Placing order...', name: 'CheckoutCubit');

    // Tạo đối tượng OrderModel từ state hiện tại
    final order = OrderModel(
      userId: _currentUserId,
      items: cartState.items.map((cartItem) => OrderItemModel.fromCartItem(cartItem)).toList(),
      shippingAddress: state.selectedAddress!,
      subtotal: cartState.totalPrice,
      shippingFee: 0.0, // Sẽ tính toán sau
      discount: 0.0, // Sẽ thêm logic sau
      total: cartState.totalPrice, // Tạm thời
      // Không cần truyền createdAt nữa, toMap() sẽ lo việc này
    );

    // Gọi repository để tạo đơn hàng
    final result = await _orderRepository.createOrder(order);

    result.fold(
            (failure) {
          emit(state.copyWith(status: CheckoutStatus.error, errorMessage: failure.message));
        },
            (orderId) {
          developer.log('CheckoutCubit: Order placed successfully with ID $orderId', name: 'CheckoutCubit');
          // Đặt hàng thành công, cập nhật trạng thái
          emit(state.copyWith(status: CheckoutStatus.orderSuccess));
          // Làm mới giỏ hàng (CartRepository đã xóa giỏ hàng, giờ chỉ cần báo cho CartCubit biết)
          _cartCubit.loadCart();
        }
    );
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
