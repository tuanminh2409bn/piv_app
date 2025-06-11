import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
// Import các model thật với đường dẫn đã thống nhất
import 'package:piv_app/features/home/data/models/category_model.dart';
import 'package:piv_app/features/home/data/models/banner_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/data/models/news_article_model.dart';

abstract class HomeRepository {
  /// Lấy 3 danh mục gốc để hiển thị trên trang chủ
  Future<Either<Failure, List<CategoryModel>>> getFeaturedCategories();

  /// Lấy tất cả các danh mục gốc (có parentId là null)
  Future<Either<Failure, List<CategoryModel>>> getAllCategories();

  /// Lấy danh sách các danh mục con trực tiếp của một danh mục cha
  Future<Either<Failure, List<CategoryModel>>> getSubCategories(String parentId);

  /// Lấy danh sách sản phẩm thuộc một danh mục cụ thể
  Future<Either<Failure, List<ProductModel>>> getProductsByCategoryId(String categoryId);

  /// Lấy danh sách banner
  Future<Either<Failure, List<BannerModel>>> getBanners();

  /// Lấy danh sách sản phẩm nổi bật
  Future<Either<Failure, List<ProductModel>>> getFeaturedProducts();

  /// Lấy danh sách tin tức mới nhất
  Future<Either<Failure, List<NewsArticleModel>>> getLatestNewsArticles({int limit = 3});

  /// Lấy chi tiết một bài viết
  Future<Either<Failure, NewsArticleModel>> getNewsArticleById(String articleId);

  /// Lấy chi tiết một sản phẩm
  Future<Either<Failure, ProductModel>> getProductById(String productId);
}
