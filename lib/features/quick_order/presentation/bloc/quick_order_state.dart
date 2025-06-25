part of 'quick_order_cubit.dart';

enum QuickOrderStatus { initial, loading, success, error, submitting }

class QuickOrderState extends Equatable {
  final QuickOrderStatus status;
  final List<ProductModel> allProducts; // Danh sách tất cả sản phẩm để tìm kiếm
  final List<OrderLine> orderLines;
  final String? errorMessage;

  const QuickOrderState({
    this.status = QuickOrderStatus.initial,
    this.allProducts = const [],
    this.orderLines = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, allProducts, orderLines, errorMessage];

  QuickOrderState copyWith({
    QuickOrderStatus? status,
    List<ProductModel>? allProducts,
    List<OrderLine>? orderLines,
    String? errorMessage,
  }) {
    return QuickOrderState(
      status: status ?? this.status,
      allProducts: allProducts ?? this.allProducts,
      orderLines: orderLines ?? this.orderLines,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}