import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/features/home/data/models/category_model.dart';
import 'package:piv_app/features/home/data/models/banner_model.dart';
// Import ProductModel thật
import 'package:piv_app/features/home/data/models/product_model.dart';
// (Sẽ import NewsArticleModel thật sau)

abstract class HomeRepository {
  Future<Either<Failure, List<CategoryModel>>> getFeaturedCategories();
  Future<Either<Failure, List<BannerModel>>> getBanners();

  // Lấy danh sách các sản phẩm nổi bật
  Future<Either<Failure, List<ProductModel>>> getFeaturedProducts();

// (Sẽ thêm các phương thức khác sau)
// Future<Either<Failure, List<NewsArticleModel>>> getNewsArticles();
}
    