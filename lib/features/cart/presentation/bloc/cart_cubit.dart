// lib/features/cart/presentation/bloc/cart_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/cart_item_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/data/models/packaging_option_model.dart';
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

  Future<void> addProduct({
    required ProductModel product,
    required PackagingOptionModel selectedOption,
    required int quantity,
  }) async {
    final userId = _userId;
    if (userId.isEmpty) return;

    final authState = _authBloc.state;
    String userRole = 'agent_2'; // Giá trị mặc định
    if (authState is AuthAuthenticated) {
      userRole = authState.user.role;
    }

    emit(state.copyWith(status: CartStatus.itemAdding));

    // ======================== LOGIC ĐÃ SỬA LỖI ========================
    // 1. Lấy giá của MỘT sản phẩm lẻ dựa trên vai trò người dùng.
    final double singleItemPrice = selectedOption.getPriceForRole(userRole);

    // 2. Tạo đối tượng CartItemModel với thông tin chính xác.
    final cartItem = CartItemModel(
      productId: product.id,
      productName: product.name,
      imageUrl: product.imageUrl,
      price: singleItemPrice, // <<< SỬA: Truyền trực tiếp giá của sản phẩm lẻ
      itemUnitName: selectedOption.unit,
      quantity: quantity, // Số lượng thùng
      quantityPerPackage: selectedOption.quantityPerPackage, // Số sản phẩm lẻ trong 1 thùng
      caseUnitName: selectedOption.name, // Tên quy cách ("Thùng...")
      categoryId: product.categoryId,
    );
    // ================================================================

    final result = await _cartRepository.addProductToCart(userId: userId, item: cartItem);

    result.fold(
          (failure) => emit(state.copyWith(status: CartStatus.error, errorMessage: failure.message)),
          (_) {
        emit(state.copyWith(status: CartStatus.itemAddedSuccess));
        loadCart();
      },
    );
  }

  Future<void> updateQuantity(String productId, String caseUnitName, int newQuantity) async {
    final userId = _userId;
    if (userId.isEmpty) return;
    emit(state.copyWith(status: CartStatus.itemUpdating));
    final result = await _cartRepository.updateProductQuantity(
      userId: userId,
      productId: productId,
      caseUnitName: caseUnitName,
      newQuantity: newQuantity,
    );
    result.fold(
          (failure) => emit(state.copyWith(status: CartStatus.error, errorMessage: failure.message)),
          (_) => loadCart(),
    );
  }

  Future<void> removeProduct(String productId, String caseUnitName) async {
    final userId = _userId;
    if (userId.isEmpty) return;
    emit(state.copyWith(status: CartStatus.itemRemoving));
    final result = await _cartRepository.removeProductFromCart(
      userId: userId,
      productId: productId,
      caseUnitName: caseUnitName,
    );
    result.fold(
          (failure) => emit(state.copyWith(status: CartStatus.error, errorMessage: failure.message)),
          (_) {
        emit(state.copyWith(status: CartStatus.itemRemovedSuccess));
        loadCart();
      },
    );
  }

  Future<void> clearCart() async {
    final userId = _userId;
    if (userId.isEmpty) return;

    final result = await _cartRepository.clearCart(userId);

    result.fold(
          (failure) {
        developer.log('Failed to clear cart: ${failure.message}', name: 'CartCubit');
      },
          (_) {
        emit(const CartState(status: CartStatus.success));
        developer.log('Cart cleared successfully for user $userId', name: 'CartCubit');
      },
    );
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}