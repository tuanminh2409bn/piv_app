part of 'category_products_cubit.dart';

enum CategoryProductsStatus { initial, loading, success, error }

class CategoryProductsState extends Equatable {
  final CategoryProductsStatus status;
  // Danh sách các danh mục con của danh mục hiện tại
  final List<CategoryModel> subCategories;
  // Danh sách các sản phẩm của danh mục hiện tại
  final List<ProductModel> products;
  final String? errorMessage;
  // Danh mục hiện tại đang được xem
  final CategoryModel? currentCategory;

  const CategoryProductsState({
    this.status = CategoryProductsStatus.initial,
    this.subCategories = const [],
    this.products = const [],
    this.errorMessage,
    this.currentCategory,
  });

  @override
  List<Object?> get props => [status, subCategories, products, errorMessage, currentCategory];

  CategoryProductsState copyWith({
    CategoryProductsStatus? status,
    List<CategoryModel>? subCategories,
    List<ProductModel>? products,
    String? errorMessage,
    CategoryModel? currentCategory,
  }) {
    return CategoryProductsState(
      status: status ?? this.status,
      subCategories: subCategories ?? this.subCategories,
      products: products ?? this.products,
      errorMessage: errorMessage ?? this.errorMessage,
      currentCategory: currentCategory ?? this.currentCategory,
    );
  }
}
