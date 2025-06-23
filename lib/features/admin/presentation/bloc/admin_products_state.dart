part of 'admin_products_cubit.dart';

enum AdminProductsStatus { initial, loading, success, error }

class AdminProductsState extends Equatable {
  final AdminProductsStatus status;
  final List<ProductModel> allProducts;
  final List<ProductModel> filteredProducts;
  final String? errorMessage;
  // --- THÊM TRƯỜNG MỚI ĐỂ LƯU TRỮ TỪ KHÓA TÌM KIẾM ---
  final String searchQuery;

  const AdminProductsState({
    this.status = AdminProductsStatus.initial,
    this.allProducts = const [],
    this.filteredProducts = const [],
    this.errorMessage,
    this.searchQuery = '', // Giá trị mặc định
  });

  @override
  List<Object?> get props => [status, allProducts, filteredProducts, errorMessage, searchQuery];

  AdminProductsState copyWith({
    AdminProductsStatus? status,
    List<ProductModel>? allProducts,
    List<ProductModel>? filteredProducts,
    String? errorMessage,
    String? searchQuery, // Thêm vào copyWith
  }) {
    return AdminProductsState(
      status: status ?? this.status,
      allProducts: allProducts ?? this.allProducts,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}