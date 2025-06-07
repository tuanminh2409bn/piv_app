import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
// Import các model thật
import 'package:piv_app/features/home/data/models/category_model.dart';
import 'package:piv_app/features/home/data/models/banner_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/data/models/news_article_model.dart';
// Import interface
import 'package:piv_app/features/home/domain/repositories/home_repository.dart';
import 'dart:developer' as developer;

class HomeRepositoryImpl implements HomeRepository {
  final FirebaseFirestore _firestore;

  HomeRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ... (các phương thức khác không đổi) ...
  @override
  Future<Either<Failure, List<CategoryModel>>> getFeaturedCategories() async {
    try {
      final querySnapshot = await _firestore.collection('categories').limit(3).get();
      final categories = querySnapshot.docs.map((doc) => CategoryModel.fromSnapshot(doc)).toList();
      return Right(categories);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải danh mục: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<BannerModel>>> getBanners() async {
    try {
      final querySnapshot = await _firestore.collection('banners').limit(5).get();
      final banners = querySnapshot.docs.map((doc) => BannerModel.fromSnapshot(doc)).toList();
      return Right(banners);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi tải banner: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải banner: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ProductModel>>> getFeaturedProducts() async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('isFeatured', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(4)
          .get();
      final products = querySnapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)).toList();
      return Right(products);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi tải sản phẩm nổi bật: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải sản phẩm nổi bật: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<NewsArticleModel>>> getLatestNewsArticles({int limit = 3}) async {
    try {
      final querySnapshot = await _firestore
          .collection('newsArticles')
          .orderBy('publishedDate', descending: true)
          .limit(limit)
          .get();
      final articles = querySnapshot.docs.map((doc) => NewsArticleModel.fromSnapshot(doc)).toList();
      return Right(articles);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi tải tin tức: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải tin tức: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, NewsArticleModel>> getNewsArticleById(String articleId) async {
    try {
      final docSnapshot = await _firestore.collection('newsArticles').doc(articleId).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return Right(NewsArticleModel.fromSnapshot(docSnapshot));
      } else {
        return Left(ServerFailure('Không tìm thấy bài viết.'));
      }
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi tải chi tiết tin tức: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải chi tiết tin tức: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ProductModel>> getProductById(String productId) async {
    try {
      final docSnapshot = await _firestore.collection('products').doc(productId).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return Right(ProductModel.fromSnapshot(docSnapshot));
      } else {
        return Left(ServerFailure('Không tìm thấy sản phẩm.'));
      }
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi tải chi tiết sản phẩm: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải chi tiết sản phẩm: ${e.toString()}'));
    }
  }

  // ** IMPLEMENT PHƯƠNG THỨC MỚI **
  @override
  Future<Either<Failure, List<CategoryModel>>> getAllCategories() async {
    try {
      // Sắp xếp theo tên để danh sách ổn định
      final querySnapshot = await _firestore.collection('categories').orderBy('name').get();

      final categories = querySnapshot.docs
          .map((doc) => CategoryModel.fromSnapshot(doc))
          .toList();
      developer.log('Fetched all ${categories.length} categories from Firestore.', name: 'HomeRepository');
      return Right(categories);

    } on FirebaseException catch (e) {
      developer.log('FirebaseException in getAllCategories: ${e.message}', name: 'HomeRepository');
      return Left(ServerFailure('Lỗi Firebase: ${e.message}'));
    } catch (e) {
      developer.log('Unknown error in getAllCategories: ${e.toString()}', name: 'HomeRepository');
      return Left(ServerFailure('Lỗi không xác định khi tải danh mục: ${e.toString()}'));
    }
  }
}
