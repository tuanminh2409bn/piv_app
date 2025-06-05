import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/features/home/data/models/category_model.dart';
import 'package:piv_app/features/home/data/models/banner_model.dart';
// Import ProductModel thật
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/home/domain/repositories/home_repository.dart';
import 'dart:developer' as developer;

class HomeRepositoryImpl implements HomeRepository {
  final FirebaseFirestore _firestore;

  HomeRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Either<Failure, List<CategoryModel>>> getFeaturedCategories() async {
    // ... (code không đổi)
    try {
      final querySnapshot = await _firestore
          .collection('categories')
          .limit(3)
          .get();
      final categories = querySnapshot.docs
          .map((doc) => CategoryModel.fromSnapshot(doc))
          .toList();
      developer.log('Fetched ${categories.length} categories from Firestore.', name: 'HomeRepository');
      return Right(categories);
    } on FirebaseException catch (e) {
      developer.log('FirebaseException in getFeaturedCategories: ${e.message}', name: 'HomeRepository');
      return Left(ServerFailure('Lỗi Firebase: ${e.message}'));
    } catch (e) {
      developer.log('Unknown error in getFeaturedCategories: ${e.toString()}', name: 'HomeRepository');
      return Left(ServerFailure('Lỗi không xác định khi tải danh mục: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<BannerModel>>> getBanners() async {
    // ... (code không đổi)
    try {
      final querySnapshot = await _firestore
          .collection('banners')
          .limit(5)
          .get();
      final banners = querySnapshot.docs
          .map((doc) => BannerModel.fromSnapshot(doc))
          .toList();
      developer.log('Fetched ${banners.length} banners from Firestore.', name: 'HomeRepository');
      return Right(banners);
    } on FirebaseException catch (e) {
      developer.log('FirebaseException in getBanners: ${e.message}', name: 'HomeRepository');
      return Left(ServerFailure('Lỗi Firebase khi tải banner: ${e.message}'));
    } catch (e) {
      developer.log('Unknown error in getBanners: ${e.toString()}', name: 'HomeRepository');
      return Left(ServerFailure('Lỗi không xác định khi tải banner: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ProductModel>>> getFeaturedProducts() async {
    try {
      // Giả sử bạn có collection 'products' và trường 'isFeatured'
      final querySnapshot = await _firestore
          .collection('products')
          .where('isFeatured', isEqualTo: true) // Lọc sản phẩm nổi bật
          .orderBy('createdAt', descending: true) // Sắp xếp theo ngày tạo mới nhất (tùy chọn)
          .limit(4) // Giới hạn số lượng sản phẩm nổi bật hiển thị
          .get();

      final products = querySnapshot.docs
          .map((doc) => ProductModel.fromSnapshot(doc))
          .toList();

      developer.log('Fetched ${products.length} featured products from Firestore.', name: 'HomeRepository');
      return Right(products);

    } on FirebaseException catch (e) {
      developer.log('FirebaseException in getFeaturedProducts: ${e.message}', name: 'HomeRepository');
      return Left(ServerFailure('Lỗi Firebase khi tải sản phẩm nổi bật: ${e.message}'));
    } catch (e) {
      developer.log('Unknown error in getFeaturedProducts: ${e.toString()}', name: 'HomeRepository');
      return Left(ServerFailure('Lỗi không xác định khi tải sản phẩm nổi bật: ${e.toString()}'));
    }
  }

// Implement các phương thức khác ở đây
}
    