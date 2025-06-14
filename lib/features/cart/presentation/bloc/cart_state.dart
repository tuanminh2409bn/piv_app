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

  /// Getter để tính tổng SỐ LƯỢNG của tất cả các sản phẩm.
  int get totalQuantity {
    if (items.isEmpty) return 0;
    return items.fold(0, (total, current) => total + current.quantity);
  }

  /// **GETTER MỚI:** Chỉ đếm số LOẠI sản phẩm trong giỏ hàng.
  int get uniqueItemCount => items.length;

  /// Getter để tính tổng tiền.
  double get totalPrice {
    if (items.isEmpty) return 0;
    return items.fold(0.0, (total, current) => total + (current.price * current.quantity));
  }

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
