part of 'cart_cubit.dart'; // Sẽ tạo file cart_cubit.dart sau

enum CartStatus {
  initial, // Trạng thái ban đầu, chưa tải
  loading, // Đang tải giỏ hàng
  success, // Tải thành công
  error,   // Có lỗi xảy ra
  itemAdding, // Đang thêm sản phẩm
  itemUpdating, // Đang cập nhật sản phẩm
  itemRemoving, // Đang xóa sản phẩm
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

  // Getter tiện ích để tính tổng số lượng sản phẩm
  int get totalItems {
    if (items.isEmpty) return 0;
    return items.fold(0, (total, current) => total + current.quantity);
  }

  // Getter tiện ích để tính tổng tiền
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
  List<Object?> get props => [status, items, errorMessage, totalItems, totalPrice];
}
