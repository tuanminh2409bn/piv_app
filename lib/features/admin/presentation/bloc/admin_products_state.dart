part of 'admin_products_cubit.dart';

enum AdminProductsStatus { initial, loading, success, error }

class AdminProductsState extends Equatable {
  final AdminProductsStatus status;
  // Danh sách đầy đủ tất cả sản phẩm
  final List<ProductModel> allProducts;
  // Danh sách sản phẩm đã được lọc (dựa trên tìm kiếm)
  final List<ProductModel> filteredProducts;
  final String? errorMessage;

  const AdminProductsState({
    this.status = AdminProductsStatus.initial,
    this.allProducts = const [],
    this.filteredProducts = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, allProducts, filteredProducts, errorMessage];

  AdminProductsState copyWith({
    AdminProductsStatus? status,
    List<ProductModel>? allProducts,
    List<ProductModel>? filteredProducts,
    String? errorMessage,
  }) {
    return AdminProductsState(
      status: status ?? this.status,
      allProducts: allProducts ?? this.allProducts,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
