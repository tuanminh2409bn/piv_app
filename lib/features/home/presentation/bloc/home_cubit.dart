import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/core/error/failure.dart';
// Import các Model thật
import 'package:piv_app/data/models/news_article_model.dart';
import 'package:piv_app/features/home/data/models/banner_model.dart';
import 'package:piv_app/features/home/data/models/category_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
// Import Repository
import 'package:piv_app/features/home/domain/repositories/home_repository.dart';
import 'dart:developer' as developer;

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _homeRepository;

  HomeCubit({required HomeRepository homeRepository})
      : _homeRepository = homeRepository,
        super(const HomeState());

  /// Tải tất cả dữ liệu cần thiết cho trang chủ một cách đồng thời
  Future<void> fetchHomeScreenData() async {
    emit(state.copyWith(status: HomeStatus.loading));
    developer.log('HomeCubit: Fetching all home screen data...', name: 'HomeCubit');

    try {
      // Sử dụng Future.wait để tải đồng thời nhiều nguồn dữ liệu, tăng tốc độ tải trang
      final results = await Future.wait([
        _homeRepository.getBanners(),
        _homeRepository.getFeaturedCategories(),
        _homeRepository.getFeaturedProducts(),
        _homeRepository.getLatestNewsArticles(),
        _homeRepository.getAllCategories(),
      ]);

      // Ép kiểu kết quả từ Future.wait một cách an toàn
      final bannersResult = results[0] as Either<Failure, List<BannerModel>>;
      final featuredCategoriesResult = results[1] as Either<Failure, List<CategoryModel>>;
      final featuredProductsResult = results[2] as Either<Failure, List<ProductModel>>;
      final newsResult = results[3] as Either<Failure, List<NewsArticleModel>>;
      final allCategoriesResult = results[4] as Either<Failure, List<CategoryModel>>;

      // Xử lý từng kết quả và thu thập lỗi (nếu có)
      List<BannerModel> finalBanners = [];
      String? bannerError;
      bannersResult.fold((f) => bannerError = f.message, (r) => finalBanners = r);

      List<CategoryModel> finalFeaturedCategories = [];
      String? categoryError;
      featuredCategoriesResult.fold((f) => categoryError = f.message, (r) => finalFeaturedCategories = r);

      List<ProductModel> finalFeaturedProducts = [];
      String? productError;
      featuredProductsResult.fold((f) => productError = f.message, (r) => finalFeaturedProducts = r);

      List<NewsArticleModel> finalNews = [];
      String? newsError;
      newsResult.fold((f) => newsError = f.message, (r) => finalNews = r);

      List<CategoryModel> finalAllCategories = [];
      String? allCategoryError;
      allCategoriesResult.fold((f) => allCategoryError = f.message, (r) => finalAllCategories = r);

      final errors = [bannerError, categoryError, productError, newsError, allCategoryError]
          .where((e) => e != null)
          .toList();

      if (errors.isNotEmpty) {
        final combinedErrorMessage = errors.join('\n');
        developer.log('HomeCubit: Error fetching data - $combinedErrorMessage', name: 'HomeCubit');
        emit(state.copyWith(
          status: HomeStatus.error,
          errorMessage: combinedErrorMessage,
        ));
      } else {
        developer.log('HomeCubit: All data fetched successfully.', name: 'HomeCubit');
        emit(state.copyWith(
          status: HomeStatus.success,
          banners: finalBanners,
          categories: finalFeaturedCategories,
          allCategories: finalAllCategories,
          featuredProducts: finalFeaturedProducts,
          filteredFeaturedProducts: finalFeaturedProducts, // Gán vào danh sách lọc
          newsArticles: finalNews,
        ));
      }

    } catch (e) {
      developer.log('HomeCubit: Unknown error fetching home screen data - ${e.toString()}', name: 'HomeCubit');
      emit(state.copyWith(status: HomeStatus.error, errorMessage: 'Lỗi không xác định: ${e.toString()}'));
    }
  }

  /// Lọc danh sách sản phẩm nổi bật dựa trên từ khóa tìm kiếm
  void searchFeaturedProducts(String query) {
    if (query.isEmpty) {
      // Nếu không tìm kiếm, hiển thị lại toàn bộ danh sách nổi bật
      emit(state.copyWith(filteredFeaturedProducts: state.featuredProducts));
      return;
    }

    final lowerCaseQuery = query.toLowerCase();
    final filtered = state.featuredProducts.where((product) {
      // Tìm kiếm theo tên sản phẩm (không phân biệt hoa thường)
      return product.name.toLowerCase().contains(lowerCaseQuery);
    }).toList();

    emit(state.copyWith(filteredFeaturedProducts: filtered));
  }
}