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

  CollectionReference get _categoriesCollection => _firestore.collection('categories');
  CollectionReference get _productsCollection => _firestore.collection('products');
  CollectionReference get _bannersCollection => _firestore.collection('banners');
  CollectionReference get _newsArticlesCollection => _firestore.collection('newsArticles');

  @override
  Future<Either<Failure, List<CategoryModel>>> getFeaturedCategories() async {
    try {
      final querySnapshot = await _categoriesCollection
          .where('parentId', isNull: true)
          .limit(3)
          .get();
      final categories = querySnapshot.docs.map((doc) => CategoryModel.fromSnapshot(doc)).toList();
      return Right(categories);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi tải danh mục nổi bật: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải danh mục nổi bật: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CategoryModel>>> getAllCategories() async {
    try {
      final querySnapshot = await _categoriesCollection
          .orderBy('name')
          .get();
      final categories = querySnapshot.docs.map((doc) => CategoryModel.fromSnapshot(doc)).toList();
      return Right(categories);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi tải tất cả danh mục: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải tất cả danh mục: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CategoryModel>>> getSubCategories(String parentId) async {
    try {
      final querySnapshot = await _categoriesCollection
          .where('parentId', isEqualTo: parentId)
          .orderBy('name')
          .get();
      final categories = querySnapshot.docs.map((doc) => CategoryModel.fromSnapshot(doc)).toList();
      return Right(categories);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi tải danh mục con: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải danh mục con: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ProductModel>>> getProductsByCategoryId(String categoryId) async {
    try {
      final querySnapshot = await _productsCollection
          .where('categoryId', isEqualTo: categoryId)
          .get();
      final products = querySnapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)).toList();
      return Right(products);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi tải sản phẩm theo danh mục: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải sản phẩm theo danh mục: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<BannerModel>>> getBanners() async {
    try {
      final querySnapshot = await _bannersCollection.limit(5).get();
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
      // ‼️ BƯỚC 1: LẤY MỘT NHÓM LỚN HƠN (VÍ DỤ 20) ĐỂ TẠO BỘ NGUỒN NGẪU NHIÊN ‼️
      final querySnapshot = await _productsCollection
          .where('isFeatured', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(20) // Lấy 20 sản phẩm nổi bật mới nhất
          .get();

      final products = querySnapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)).toList();

      // ‼️ BƯỚC 2: XÁO TRỘN NGẪU NHIÊN DANH SÁCH NÀY ‼️
      products.shuffle();

      // ‼️ BƯỚC 3: CHỌN RA 6 SẢN PHẨM ĐẦU TIÊN ĐỂ HIỂN THỊ ‼️
      return Right(products.take(6).toList());

    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi tải sản phẩm nổi bật: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải sản phẩm nổi bật: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<NewsArticleModel>>> getLatestNewsArticles({int limit = 3}) async {
    try {
      final querySnapshot = await _newsArticlesCollection
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
      final docSnapshot = await _newsArticlesCollection.doc(articleId).get();
      if (docSnapshot.exists) {
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
      final docSnapshot = await _productsCollection.doc(productId).get();
      if (docSnapshot.exists) {
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

  @override
  Future<Either<Failure, List<ProductModel>>> getAllProducts() async {
    try {
      final querySnapshot = await _productsCollection.orderBy('name').get();
      final products = querySnapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)).toList();
      developer.log('Fetched all ${products.length} products.', name: 'HomeRepository');
      return Right(products);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải sản phẩm: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> createProduct(ProductModel product) async {
    try {
      final docRef = await _productsCollection.add(product.toJson());
      developer.log('Created new product with ID: ${docRef.id}', name: 'HomeRepository');
      return Right(docRef.id);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi tạo sản phẩm: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tạo sản phẩm: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateProduct(ProductModel product) async {
    try {
      await _productsCollection.doc(product.id).update(product.toJson());
      developer.log('Updated product with ID: ${product.id}', name: 'HomeRepository');
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi cập nhật sản phẩm: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi cập nhật sản phẩm: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteProduct(String productId) async {
    try {
      await _productsCollection.doc(productId).delete();
      developer.log('Deleted product with ID: $productId', name: 'HomeRepository');
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi xóa sản phẩm: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi xóa sản phẩm: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> createCategory(CategoryModel category) async {
    try {
      final docRef = await _categoriesCollection.add(category.toJson());
      developer.log('Created new category with ID: ${docRef.id}', name: 'HomeRepository');
      return Right(docRef.id);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi tạo danh mục: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tạo danh mục: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateCategory(CategoryModel category) async {
    try {
      await _categoriesCollection.doc(category.id).update(category.toJson());
      developer.log('Updated category with ID: ${category.id}', name: 'HomeRepository');
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi cập nhật danh mục: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi cập nhật danh mục: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteCategory(String categoryId) async {
    try {
      await _categoriesCollection.doc(categoryId).delete();
      developer.log('Deleted category with ID: $categoryId', name: 'HomeRepository');
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi xóa danh mục: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi xóa danh mục: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ProductModel>>> getProductsByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return const Right([]); // Trả về danh sách rỗng nếu không có ID nào
    }
    try {
      // Firestore cho phép truy vấn tối đa 30 item trong một lệnh `whereIn`
      final querySnapshot = await _productsCollection
          .where(FieldPath.documentId, whereIn: ids)
          .get();
      final products = querySnapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)).toList();
      return Right(products);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi tải sản phẩm yêu thích: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateProductField(String productId, Map<String, dynamic> data) async {
    try {
      await _productsCollection.doc(productId).update(data);
      developer.log('Updated field for product ID: $productId', name: 'HomeRepository');
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi cập nhật trường sản phẩm: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi cập nhật trường sản phẩm: ${e.toString()}'));
    }
  }
}
