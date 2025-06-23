import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
// Import các model thật
import 'package:piv_app/features/home/data/models/category_model.dart';
import 'package:piv_app/features/home/data/models/banner_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/data/models/news_article_model.dart';

abstract class HomeRepository {
  // Methods cho User
  Future<Either<Failure, List<CategoryModel>>> getFeaturedCategories();
  Future<Either<Failure, List<CategoryModel>>> getAllCategories();
  Future<Either<Failure, List<CategoryModel>>> getSubCategories(String parentId);
  Future<Either<Failure, List<ProductModel>>> getProductsByCategoryId(String categoryId);
  Future<Either<Failure, List<BannerModel>>> getBanners();
  Future<Either<Failure, List<ProductModel>>> getFeaturedProducts();
  Future<Either<Failure, List<NewsArticleModel>>> getLatestNewsArticles({int limit = 3});
  Future<Either<Failure, NewsArticleModel>> getNewsArticleById(String articleId);
  Future<Either<Failure, ProductModel>> getProductById(String productId);

  // Methods cho Admin quản lý sản phẩm
  Future<Either<Failure, List<ProductModel>>> getAllProducts();
  Future<Either<Failure, String>> createProduct(ProductModel product);
  Future<Either<Failure, Unit>> updateProduct(ProductModel product);
  Future<Either<Failure, Unit>> deleteProduct(String productId);

  Future<Either<Failure, Unit>> updateProductField(String productId, Map<String, dynamic> data);

  // ** PHƯƠNG THỨC MỚI CHO ADMIN QUẢN LÝ DANH MỤC **
  /// Tạo một danh mục mới
  Future<Either<Failure, String>> createCategory(CategoryModel category);

  /// Cập nhật một danh mục đã có
  Future<Either<Failure, Unit>> updateCategory(CategoryModel category);

  /// Xóa một danh mục
  Future<Either<Failure, Unit>> deleteCategory(String categoryId);

  /// Lấy danh sách sản phẩm dựa trên một danh sách các ID.
  Future<Either<Failure, List<ProductModel>>> getProductsByIds(List<String> ids);
}
