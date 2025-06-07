import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
// Import các model thật với đường dẫn bạn đã cung cấp
import 'package:piv_app/features/home/data/models/category_model.dart';
import 'package:piv_app/features/home/data/models/banner_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/data/models/news_article_model.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<CategoryModel>>> getFeaturedCategories();
  Future<Either<Failure, List<BannerModel>>> getBanners();
  Future<Either<Failure, List<ProductModel>>> getFeaturedProducts();
  Future<Either<Failure, List<NewsArticleModel>>> getLatestNewsArticles({int limit = 3});
  Future<Either<Failure, NewsArticleModel>> getNewsArticleById(String articleId);

  // Lấy chi tiết một sản phẩm dựa trên ID
  Future<Either<Failure, ProductModel>> getProductById(String productId);
}
    