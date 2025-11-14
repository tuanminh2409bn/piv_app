import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/features/home/data/models/category_model.dart';
import 'package:piv_app/features/home/data/models/banner_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/data/models/news_article_model.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<CategoryModel>>> getFeaturedCategories();
  Future<Either<Failure, List<CategoryModel>>> getAllCategories();
  Future<Either<Failure, List<CategoryModel>>> getSubCategories(String parentId);
  Future<Either<Failure, List<ProductModel>>> getProductsByCategoryId(String categoryId, {String? currentUserId});
  Future<Either<Failure, List<BannerModel>>> getBanners();
  Future<Either<Failure, List<ProductModel>>> getFeaturedProducts({String? currentUserId});
  Future<Either<Failure, List<NewsArticleModel>>> getLatestNewsArticles({int limit = 3});
  Future<Either<Failure, NewsArticleModel>> getNewsArticleById(String articleId);
  Future<Either<Failure, ProductModel>> getProductById(String productId, {String? currentUserId});
  Future<Either<Failure, List<ProductModel>>> getAllProducts({String? currentUserId});
  Future<Either<Failure, String>> createProduct(ProductModel product);
  Future<Either<Failure, Unit>> updateProduct(ProductModel product);
  Future<Either<Failure, Unit>> deleteProduct(String productId);
  Future<Either<Failure, Unit>> updateProductField(String productId, Map<String, dynamic> data);
  Future<Either<Failure, String>> createCategory(CategoryModel category);
  Future<Either<Failure, Unit>> updateCategory(CategoryModel category);
  Future<Either<Failure, Unit>> deleteCategory(String categoryId);
  Future<Either<Failure, List<ProductModel>>> getProductsByIds(List<String> ids, {String? currentUserId});
}
