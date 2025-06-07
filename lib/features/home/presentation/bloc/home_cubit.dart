// 1. TẤT CẢ CÁC IMPORT PHẢI ĐẶT LÊN ĐẦU TIÊN
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';    // HomeState và các model giả trong HomeState dùng Equatable
import 'package:dartz/dartz.dart';             // Cho Either
import 'package:piv_app/core/error/failure.dart';     // Cho Failure
import 'package:piv_app/features/home/domain/repositories/home_repository.dart';
// Import CÁC MODEL THẬT mà HomeCubit và HomeState sẽ sử dụng
import 'package:piv_app/features/home/data/models/category_model.dart'; // Đường dẫn đã ghi nhớ
import 'package:piv_app/features/home/data/models/banner_model.dart'; // Đường dẫn đã ghi nhớ
import 'package:piv_app/features/home/data/models/product_model.dart'; // Đường dẫn đã ghi nhớ
import 'package:piv_app/data/models/news_article_model.dart'; // Model NewsArticle thật
import 'dart:developer' as developer;

// 2. PART DIRECTIVE ĐẶT SAU TẤT CẢ CÁC IMPORT
part 'home_state.dart'; // home_state.dart chứa HomeState và các model giả còn lại (nếu có)

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _homeRepository;

  HomeCubit({required HomeRepository homeRepository})
      : _homeRepository = homeRepository,
  // HomeState, HomeStatus, và các model giả (ProductModel, NewsArticleModel nếu còn trong home_state.dart)
  // sẽ được "nhìn thấy" từ home_state.dart do khai báo 'part'.
        super(const HomeState());

  Future<void> fetchHomeScreenData() async {
    emit(state.copyWith(status: HomeStatus.loading, clearErrorMessage: true));
    developer.log('HomeCubit: Fetching all home screen data from Firestore...', name: 'HomeCubit');

    try {
      final results = await Future.wait([
        _homeRepository.getBanners(),           // Trả về Either<Failure, List<BannerModel thật>>
        _homeRepository.getFeaturedCategories(),// Trả về Either<Failure, List<CategoryModel thật>>
        _homeRepository.getFeaturedProducts(),  // Trả về Either<Failure, List<ProductModel thật>>
        _homeRepository.getLatestNewsArticles(),// Trả về Either<Failure, List<NewsArticleModel thật>>
      ]);

      // results[0] là cho banners, results[1] là cho categories, etc.
      final bannersResult = results[0] as Either<Failure, List<BannerModel>>;
      final categoriesResult = results[1] as Either<Failure, List<CategoryModel>>;
      final productsResult = results[2] as Either<Failure, List<ProductModel>>;
      final newsResult = results[3] as Either<Failure, List<NewsArticleModel>>;

      List<BannerModel> finalBanners = [];
      String? bannerError;
      bannersResult.fold(
            (failure) => bannerError = 'Lỗi tải banner: ${failure.message}',
            (banners) => finalBanners = banners,
      );

      List<CategoryModel> finalCategories = [];
      String? categoryError;
      categoriesResult.fold(
            (failure) => categoryError = 'Lỗi tải danh mục: ${failure.message}',
            (categories) => finalCategories = categories,
      );

      List<ProductModel> finalProducts = [];
      String? productError;
      productsResult.fold(
            (failure) => productError = 'Lỗi tải sản phẩm: ${failure.message}',
            (products) => finalProducts = products,
      );

      List<NewsArticleModel> finalNews = [];
      String? newsError;
      newsResult.fold(
            (failure) => newsError = 'Lỗi tải tin tức: ${failure.message}',
            (news) => finalNews = news,
      );

      String? combinedErrorMessage;
      final errors = [bannerError, categoryError, productError, newsError].where((e) => e != null).toList();
      if (errors.isNotEmpty) {
        combinedErrorMessage = errors.join('\n');
      }

      if (combinedErrorMessage != null) {
        developer.log('HomeCubit: Error fetching data - $combinedErrorMessage', name: 'HomeCubit');
        emit(state.copyWith(
          status: HomeStatus.error,
          errorMessage: combinedErrorMessage,
          banners: finalBanners.isNotEmpty ? finalBanners : state.banners,
          categories: finalCategories.isNotEmpty ? finalCategories : state.categories,
          featuredProducts: finalProducts.isNotEmpty ? finalProducts : state.featuredProducts,
          newsArticles: finalNews.isNotEmpty ? finalNews : state.newsArticles,
        ));
      } else {
        developer.log('HomeCubit: All data fetched successfully.', name: 'HomeCubit');
        emit(state.copyWith(
          status: HomeStatus.success,
          banners: finalBanners,
          categories: finalCategories,
          featuredProducts: finalProducts,
          newsArticles: finalNews,
        ));
      }

    } catch (e) {
      developer.log('HomeCubit: Unknown error fetching home screen data - ${e.toString()}', name: 'HomeCubit');
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: 'Lỗi không xác định: ${e.toString()}',
      ));
    }
  }
}
