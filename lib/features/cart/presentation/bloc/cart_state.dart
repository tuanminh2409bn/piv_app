// lib/features/cart/presentation/bloc/cart_state.dart

part of 'cart_cubit.dart';

enum CartStatus {
  initial,
  loading,
  success,
  error,
  itemAdding,
  itemUpdating,
  itemRemoving,
}

class CartState extends Equatable {
  final CartStatus status;
  final List<CartItemModel> items;
  final String? errorMessage;

  const CartState({
    this.status = CartStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  int get totalQuantity {
    if (items.isEmpty) return 0;
    return items.fold(0, (total, current) => total + current.quantity);
  }

  int get uniqueItemCount => items.length;

  // --- ĐẢM BẢO LOGIC NÀY ĐÚNG ---
  // Getter này tính tổng tiền của toàn bộ giỏ hàng
  double get totalPrice {
    if (items.isEmpty) return 0.0;
    // Nó sẽ cộng tổng của tất cả các `subtotal` từ mỗi CartItemModel
    return items.fold(0.0, (total, current) => total + current.subtotal);
  }
  // ------------------------------

  CartState copyWith({
    CartStatus? status,
    List<CartItemModel>? items,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return CartState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}