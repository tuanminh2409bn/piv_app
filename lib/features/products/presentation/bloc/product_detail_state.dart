// lib/features/products/presentation/bloc/product_detail_state.dart

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
  final int quantity;

  // --- THÊM MỚI ---
  // Lưu lại quy cách đóng gói người dùng đang chọn.
  final PackagingOptionModel? selectedPackagingOption;
  // ------------------

  const ProductDetailState({
    this.status = ProductDetailStatus.initial,
    this.product,
    this.errorMessage,
    this.quantity = 1,
    this.selectedPackagingOption, // Thêm vào constructor
  });

  ProductDetailState copyWith({
    ProductDetailStatus? status,
    ProductModel? product,
    String? errorMessage,
    int? quantity,
    PackagingOptionModel? selectedPackagingOption, // Thêm vào copyWith
    bool clearErrorMessage = false,
  }) {
    return ProductDetailState(
      status: status ?? this.status,
      product: product ?? this.product,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      quantity: quantity ?? this.quantity,
      selectedPackagingOption: selectedPackagingOption ?? this.selectedPackagingOption,
    );
  }

  @override
  List<Object?> get props => [status, product, errorMessage, quantity, selectedPackagingOption]; // Thêm vào props
}