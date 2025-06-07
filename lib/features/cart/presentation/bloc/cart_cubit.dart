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

    _authSubscription = _authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        _currentUserId = authState.user.id;
        loadCart();
      } else if (authState is AuthUnauthenticated) {
        _currentUserId = '';
        emit(const CartState());
      }
    });

    final initialAuthState = _authBloc.state;
    if (initialAuthState is AuthAuthenticated) {
      _currentUserId = initialAuthState.user.id;
      loadCart();
    }
  }

  String get _userId {
    if (_currentUserId.isEmpty) {
      developer.log('CartCubit: User is not logged in.', name: 'CartCubit');
      emit(state.copyWith(status: CartStatus.error, errorMessage: 'Vui lòng đăng nhập để sử dụng giỏ hàng.'));
    }
    return _currentUserId;
  }

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

  Future<void> addProduct(ProductModel product, int quantity) async {
    final userId = _userId;
    if (userId.isEmpty) return;

    emit(state.copyWith(status: CartStatus.itemAdding));
    final result = await _cartRepository.addProductToCart(
      userId: userId,
      product: product,
      quantity: quantity,
    );
    result.fold(
          (failure) => emit(state.copyWith(status: CartStatus.error, errorMessage: failure.message)),
          (_) {
        loadCart(); // Tải lại giỏ hàng để cập nhật UI
      },
    );
  }

  // ** PHƯƠNG THỨC MỚI: CẬP NHẬT SỐ LƯỢNG **
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

  // ** PHƯƠNG THỨC MỚI: XÓA SẢN PHẨM **
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
    _authSubscription?.cancel();
    return super.close();
  }
}
