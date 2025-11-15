// lib/features/home/data/repositories/home_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/features/home/data/models/category_model.dart';
import 'package:piv_app/features/home/data/models/banner_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/data/models/news_article_model.dart';
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

  // --- SỬA ĐỔI: getProductsByCategoryId ---
  @override
  Future<Either<Failure, List<ProductModel>>> getProductsByCategoryId(
      String categoryId, {
        String? currentUserId, // <-- Thêm tham số
      }) async {
    try {
      // Query 1: Lấy sản phẩm CHUNG
      // Cần Index: (categoryId, isPrivate)
      final publicQuery = _productsCollection
          .where('categoryId', isEqualTo: categoryId)
          .where('isPrivate', isEqualTo: false);

      final publicSnapshot = await publicQuery.get();
      final products = publicSnapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)).toList();

      // Query 2: Lấy sản phẩm RIÊNG (nếu đã đăng nhập)
      // Cần Index: (categoryId, ownerAgentId)
      if (currentUserId != null && currentUserId.isNotEmpty) {
        final privateQuery = _productsCollection
            .where('categoryId', isEqualTo: categoryId)
            .where('ownerAgentId', isEqualTo: currentUserId);
        final privateSnapshot = await privateQuery.get();
        products.addAll(privateSnapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)));
      }

      return Right(products);
    } on FirebaseException catch (e) {
      developer.log(
          'Lỗi getProductsByCategoryId: ${e.message}. \n'
              'Hãy chắc chắn bạn đã tạo Composite Index cho: \n'
              '1. (categoryId ASC, isPrivate ASC) \n'
              '2. (categoryId ASC, ownerAgentId ASC)',
          name: 'HomeRepositoryError'
      );
      return Left(ServerFailure('Lỗi Firebase: ${e.message}. (Bạn đã tạo Index cho query này chưa?)'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định: ${e.toString()}'));
    }
  }
  // --- KẾT THÚC SỬA ĐỔI ---

  // ... (getBanners giữ nguyên) ...
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

  // --- SỬA ĐỔI: getFeaturedProducts ---
  @override
  Future<Either<Failure, List<ProductModel>>> getFeaturedProducts({
    String? currentUserId, // <-- Thêm tham số
  }) async {
    try {
      // Query 1: Lấy sản phẩm CHUNG nổi bật
      // Cần Index: (isFeatured, isPrivate, createdAt DESC)
      final publicQuery = _productsCollection
          .where('isFeatured', isEqualTo: true)
          .where('isPrivate', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(20);

      final publicSnapshot = await publicQuery.get();
      final products = publicSnapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)).toList();

      // Query 2: Lấy sản phẩm RIÊNG nổi bật (nếu đã đăng nhập)
      // Cần Index: (isFeatured, ownerAgentId, createdAt DESC)
      if (currentUserId != null && currentUserId.isNotEmpty) {
        final privateQuery = _productsCollection
            .where('isFeatured', isEqualTo: true)
            .where('ownerAgentId', isEqualTo: currentUserId)
            .orderBy('createdAt', descending: true)
            .limit(20);
        final privateSnapshot = await privateQuery.get();
        products.addAll(privateSnapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)));
      }

      products.shuffle();
      return Right(products.take(6).toList());

    } on FirebaseException catch (e) {
      developer.log(
          'Lỗi getFeaturedProducts: ${e.message}. \n'
              'Hãy chắc chắn bạn đã tạo Composite Index cho: \n'
              '1. (isFeatured ASC, isPrivate ASC, createdAt DESC) \n'
              '2. (isFeatured ASC, ownerAgentId ASC, createdAt DESC)',
          name: 'HomeRepositoryError'
      );
      return Left(ServerFailure('Lỗi Firebase: ${e.message}. (Bạn đã tạo Index cho query này chưa?)'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định: ${e.toString()}'));
    }
  }
  // --- KẾT THÚC SỬA ĐỔI ---

  // ... (getLatestNewsArticles, getNewsArticleById giữ nguyên) ...
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

  // --- SỬA ĐỔI: getProductById ---
  @override
  Future<Either<Failure, ProductModel>> getProductById(
      String productId, {
        String? currentUserId, // <-- Thêm tham số
      }) async {
    try {
      final docSnapshot = await _productsCollection.doc(productId).get();
      if (docSnapshot.exists) {
        final product = ProductModel.fromSnapshot(docSnapshot);

        // --- THÊM LOGIC KIỂM TRA QUYỀN ---
        if (product.isPrivate) {
          // Nếu là sản phẩm riêng, kiểm tra xem có phải chủ sở hữu không
          if (product.ownerAgentId == currentUserId) {
            return Right(product); // Là chủ sở hữu
          } else {
            // Người dùng không có quyền xem
            developer.log('Access denied for product $productId. User $currentUserId is not owner.', name: 'HomeRepository');
            return Left(ServerFailure('Không tìm thấy sản phẩm.'));
          }
        } else {
          // Sản phẩm chung, ai cũng có quyền xem
          return Right(product);
        }
        // --- KẾT THÚC KIỂM TRA QUYỀN ---
      } else {
        return Left(ServerFailure('Không tìm thấy sản phẩm.'));
      }
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi tải chi tiết sản phẩm: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải chi tiết sản phẩm: ${e.toString()}'));
    }
  }
  // --- KẾT THÚC SỬA ĐỔI ---

  // --- SỬA ĐỔI: getAllProducts ---
  @override
  Future<Either<Failure, List<ProductModel>>> getAllProducts({
    String? currentUserId, // <-- Thêm tham số
  }) async {
    try {
      // Query 1: Lấy tất cả sản phẩm CHUNG
      // Cần Index: (isPrivate, name)
      final publicQuery = _productsCollection
          .where('isPrivate', isEqualTo: false)
          .orderBy('name');

      final publicSnapshot = await publicQuery.get();
      final products = publicSnapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)).toList();

      // Query 2: Nếu có user, lấy thêm sản phẩm RIÊNG của họ
      // Cần Index: (ownerAgentId, name)
      if (currentUserId != null && currentUserId.isNotEmpty) {
        final privateQuery = _productsCollection
            .where('ownerAgentId', isEqualTo: currentUserId)
            .orderBy('name');
        final privateSnapshot = await privateQuery.get();
        products.addAll(privateSnapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)));
      }

      developer.log('Fetched all ${products.length} allowed products for user $currentUserId.', name: 'HomeRepository');
      // Sắp xếp lại danh sách cuối cùng theo tên
      products.sort((a, b) => a.name.compareTo(b.name));
      return Right(products);

    } on FirebaseException catch (e) {
      developer.log(
          'Lỗi getAllProducts: ${e.message}. \n'
              'Hãy chắc chắn bạn đã tạo Composite Index cho: \n'
              '1. (isPrivate ASC, name ASC) \n'
              '2. (ownerAgentId ASC, name ASC)',
          name: 'HomeRepositoryError'
      );
      return Left(ServerFailure('Lỗi Firebase: ${e.message}. (Bạn đã tạo Index cho query này chưa?)'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải sản phẩm: ${e.toString()}'));
    }
  }
  // --- KẾT THÚC SỬA ĐỔI ---

  // ... (Các hàm create/update/delete product, category giữ nguyên) ...
  @override
  Future<Either<Failure, String>> createProduct(ProductModel product) async {
    try {
      // Dùng .toJson() đã được cập nhật
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
      // Dùng .toJson() đã được cập nhật
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

  // --- SỬA ĐỔI: getProductsByIds ---
  @override
  Future<Either<Failure, List<ProductModel>>> getProductsByIds(
      List<String> ids, {
        String? currentUserId, // <-- Thêm tham số
      }) async {
    if (ids.isEmpty) {
      return const Right([]);
    }
    try {
      final List<ProductModel> allProducts = [];
      // Phân tách thành các chunk 30 ID (giới hạn của Firestore 'whereIn')
      for (var i = 0; i < ids.length; i += 30) {
        final chunk = ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30);
        final querySnapshot = await _productsCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        allProducts.addAll(querySnapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)));
      }

      // --- THÊM LOGIC LỌC SAU KHI TẢI ---
      final filteredProducts = allProducts.where((product) {
        if (product.isPrivate) {
          // Nếu riêng tư, chỉ trả về nếu user là chủ sở hữu
          return product.ownerAgentId == currentUserId;
        }
        // Nếu không (chung), luôn trả về
        return true;
      }).toList();
      // --- KẾT THÚC LỌC ---

      return Right(filteredProducts);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi tải sản phẩm: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định: ${e.toString()}'));
    }
  }
  // --- KẾT THÚC SỬA ĐỔI ---

  // ... (updateProductField giữ nguyên) ...
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

  @override
  Future<Either<Failure, List<ProductModel>>> getAllProductsForAdmin() async {
    try {
      // Chỉ lấy và sắp xếp theo tên, không lọc (where)
      final querySnapshot = await _productsCollection
          .orderBy('name')
          .get();

      final products = querySnapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)).toList();
      developer.log('Fetched ${products.length} total products for Admin view.', name: 'HomeRepository');
      return Right(products);

    } on FirebaseException catch (e) {
      developer.log('Lỗi getAllProductsForAdmin: ${e.message}.', name: 'HomeRepositoryError');
      return Left(ServerFailure('Lỗi Firebase: ${e.message}.'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định: ${e.toString()}'));
    }
  }
}