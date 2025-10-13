// lib/features/cart/presentation/bloc/cart_state.dart

part of 'cart_cubit.dart';

enum CartStatus {
  initial,
  loading,
  success,    // Trạng thái thành công chung (ví dụ: khi tải giỏ hàng)
  error,
  itemAdding,
  itemUpdating,
  itemRemoving,
  // --- THÊM MỚI: Các trạng thái thành công cụ thể ---
  itemAddedSuccess,
  itemRemovedSuccess,
  itemUpdatedSuccess,
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

  double get totalPrice {
    if (items.isEmpty) return 0.0;
    return items.fold(0.0, (total, current) => total + current.subtotal);
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