import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/features/home/domain/repositories/home_repository.dart';
import 'package:piv_app/features/home/data/models/category_model.dart';
import 'package:piv_app/features/home/data/models/banner_model.dart';
// Import ProductModel thật
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'dart:developer' as developer;

part 'home_state.dart'; // HomeState giờ sẽ dùng ProductModel thật

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _homeRepository;

  HomeCubit({required HomeRepository homeRepository})
      : _homeRepository = homeRepository,
        super(const HomeState());

  Future<void> fetchHomeScreenData() async {
    emit(state.copyWith(status: HomeStatus.loading, clearErrorMessage: true));
    developer.log('HomeCubit: Fetching all home screen data from Firestore...', name: 'HomeCubit');

    try {
      final results = await Future.wait([
        _homeRepository.getBanners(),
        _homeRepository.getFeaturedCategories(),
        _homeRepository.getFeaturedProducts(), // << THÊM LỜI GỌI NÀY
        // TODO: Thêm lời gọi repository cho tin tức ở đây
        // _homeRepository.getNewsArticles(),
      ]);

      final bannersResult = results[0] as Either<Failure, List<BannerModel>>;
      final categoriesResult = results[1] as Either<Failure, List<CategoryModel>>;
      final productsResult = results[2] as Either<Failure, List<ProductModel>>; // << KẾT QUẢ SẢN PHẨM
      // final newsResult = results[3] as Either<Failure, List<NewsArticleModel>>; // Ví dụ

      // Dữ liệu giả cho tin tức
      final mockNews = [
        const NewsArticleModel(id: 'news1', title: 'Hội thảo Kỹ thuật Canh tác PIV', summary: 'Giải pháp phân bón tiên tiến...', imageUrl: 'https://placehold.co/80x80/a9d8c8/1B5E20?text=HoiThao'),
      ];

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

      List<ProductModel> finalProducts = []; // << DANH SÁCH SẢN PHẨM THẬT
      String? productError;
      productsResult.fold(
            (failure) => productError = 'Lỗi tải sản phẩm: ${failure.message}',
            (products) => finalProducts = products,
      );

      String? combinedErrorMessage;
      final errors = [bannerError, categoryError, productError].where((e) => e != null).toList();
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
          featuredProducts: finalProducts.isNotEmpty ? finalProducts : state.featuredProducts, // Giữ SP cũ nếu lỗi và SP mới rỗng
          newsArticles: mockNews,
        ));
      } else {
        developer.log('HomeCubit: All main data fetched successfully.', name: 'HomeCubit');
        emit(state.copyWith(
          status: HomeStatus.success,
          banners: finalBanners,
          categories: finalCategories,
          featuredProducts: finalProducts, // << SỬ DỤNG SẢN PHẨM THẬT
          newsArticles: mockNews,
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
    