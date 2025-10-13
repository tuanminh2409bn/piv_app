// lib/features/wishlist/presentation/bloc/wishlist_state.dart
part of 'wishlist_cubit.dart';

enum WishlistStatus { initial, loading, success, error }

class WishlistState extends Equatable {
  final WishlistStatus status;
  // Dùng Set<String> để lưu các productId.
  // Set giúp việc kiểm tra một sản phẩm có trong wishlist hay không rất nhanh (O(1)).
  final Set<String> productIds;
  final String? errorMessage;

  const WishlistState({
    this.status = WishlistStatus.initial,
    this.productIds = const {},
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, productIds, errorMessage];

  WishlistState copyWith({
    WishlistStatus? status,
    Set<String>? productIds,
    String? errorMessage,
  }) {
    return WishlistState(
      status: status ?? this.status,
      productIds: productIds ?? this.productIds,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}