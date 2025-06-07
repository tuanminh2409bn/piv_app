part of 'product_detail_cubit.dart';

enum ProductDetailStatus {
  initial,
  loading,
  success,
  error,
}

class ProductDetailState extends Equatable {
  final ProductDetailStatus status;
  final ProductModel? product;
  final String? errorMessage;
  final int quantity; // << THÊM TRƯỜNG NÀY

  const ProductDetailState({
    this.status = ProductDetailStatus.initial,
    this.product,
    this.errorMessage,
    this.quantity = 1, // << GIÁ TRỊ MẶC ĐỊNH LÀ 1
  });

  ProductDetailState copyWith({
    ProductDetailStatus? status,
    ProductModel? product,
    String? errorMessage,
    int? quantity, // << THÊM VÀO COPYWITH
    bool clearErrorMessage = false,
  }) {
    return ProductDetailState(
      status: status ?? this.status,
      product: product ?? this.product,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      quantity: quantity ?? this.quantity, // << GÁN GIÁ TRỊ
    );
  }

  @override
  List<Object?> get props => [status, product, errorMessage, quantity]; // << THÊM VÀO PROPS
}
    