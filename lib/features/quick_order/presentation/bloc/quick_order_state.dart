// lib/features/quick_order/presentation/bloc/quick_order_state.dart
part of 'quick_order_cubit.dart';

enum QuickOrderStatus { initial, loading, success, error }

class QuickOrderState extends Equatable {
  final QuickOrderStatus status;
  final List<ProductModel> products;
  final String? errorMessage;

  const QuickOrderState({
    this.status = QuickOrderStatus.initial,
    this.products = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, products, errorMessage];

  QuickOrderState copyWith({
    QuickOrderStatus? status,
    List<ProductModel>? products,
    String? errorMessage,
  }) {
    return QuickOrderState(
      status: status ?? this.status,
      products: products ?? this.products,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}