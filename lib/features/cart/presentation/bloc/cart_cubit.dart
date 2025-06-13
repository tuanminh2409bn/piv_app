import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/cart_item_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/cart/domain/repositories/cart_repository.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'dart:async';
import 'dart:developer' as developer;

part 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  final CartRepository _cartRepository;
  final AuthBloc _authBloc;
  StreamSubscription? _authSubscription;
  String _currentUserId = '';

  CartCubit({required CartRepository cartRepository, required AuthBloc authBloc})
      : _cartRepository = cartRepository,
        _authBloc = authBloc,
        super(const CartState()) {

    // Lắng nghe trạng thái AuthBloc để biết userId và tải giỏ hàng tương ứng
    _authSubscription = _authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        _currentUserId = authState.user.id;
        loadCart(); // Tải giỏ hàng khi người dùng đăng nhập
      } else if (authState is AuthUnauthenticated) {
        _currentUserId = '';
        emit(const CartState()); // Xóa giỏ hàng khi đăng xuất
      }
    });

    // Tải dữ liệu lần đầu nếu người dùng đã đăng nhập sẵn khi app khởi động
    final initialAuthState = _authBloc.state;
    if (initialAuthState is AuthAuthenticated) {
      _currentUserId = initialAuthState.user.id;
      loadCart();
    }
  }

  String get _userId {
    if (_currentUserId.isEmpty) {
      developer.log('CartCubit: User is not logged in.', name: 'CartCubit');
      // Tránh emit lỗi ở đây vì nó có thể gây ra SnackBar không mong muốn
      // Thay vào đó, các phương thức sẽ kiểm tra và trả về nếu cần.
    }
    return _currentUserId;
  }

  /// Tải thông tin giỏ hàng của người dùng hiện tại
  Future<void> loadCart() async {
    final userId = _userId;
    if (userId.isEmpty) return;

    emit(state.copyWith(status: CartStatus.loading));
    final result = await _cartRepository.getCart(userId);
    result.fold(
          (failure) => emit(state.copyWith(status: CartStatus.error, errorMessage: failure.message)),
          (items) => emit(state.copyWith(status: CartStatus.success, items: items)),
    );
  }

  /// Thêm một sản phẩm vào giỏ hàng với giá cụ thể
  Future<void> addProduct({
    required ProductModel product,
    required int quantity,
    required double price,
  }) async {
    final userId = _userId;
    if (userId.isEmpty) return;

    emit(state.copyWith(status: CartStatus.itemAdding));
    final result = await _cartRepository.addProductToCart(
      userId: userId,
      product: product,
      quantity: quantity,
      price: price, // Truyền giá tại thời điểm mua
    );
    result.fold(
          (failure) => emit(state.copyWith(status: CartStatus.error, errorMessage: failure.message)),
          (_) {
        // Sau khi thêm thành công, tải lại giỏ hàng để cập nhật UI
        loadCart();
      },
    );
  }

  /// Cập nhật số lượng của một sản phẩm trong giỏ hàng
  Future<void> updateQuantity(String productId, int newQuantity) async {
    final userId = _userId;
    if (userId.isEmpty) return;

    emit(state.copyWith(status: CartStatus.itemUpdating));
    final result = await _cartRepository.updateProductQuantity(
      userId: userId,
      productId: productId,
      newQuantity: newQuantity,
    );
    result.fold(
          (failure) => emit(state.copyWith(status: CartStatus.error, errorMessage: failure.message)),
          (_) => loadCart(), // Tải lại giỏ hàng
    );
  }

  /// Xóa một sản phẩm khỏi giỏ hàng
  Future<void> removeProduct(String productId) async {
    final userId = _userId;
    if (userId.isEmpty) return;

    emit(state.copyWith(status: CartStatus.itemRemoving));
    final result = await _cartRepository.removeProductFromCart(
      userId: userId,
      productId: productId,
    );
    result.fold(
          (failure) => emit(state.copyWith(status: CartStatus.error, errorMessage: failure.message)),
          (_) => loadCart(), // Tải lại giỏ hàng
    );
  }

  @override
  Future<void> close() {
    // Hủy lắng nghe stream khi Cubit bị đóng để tránh rò rỉ bộ nhớ
    _authSubscription?.cancel();
    return super.close();
  }
}
