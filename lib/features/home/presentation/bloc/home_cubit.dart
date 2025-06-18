import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/news_article_model.dart';
import 'package:piv_app/features/home/data/models/banner_model.dart';
import 'package:piv_app/features/home/data/models/category_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/home/domain/repositories/home_repository.dart';
import 'dart:developer' as developer;

part 'home_state.dart';

String _removeDiacritics(String str) {
  var withDia = 'áàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ';
  var withoutDia = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
  for (int i = 0; i < withDia.length; i++) {
    str = str.replaceAll(withDia[i], withoutDia[i]);
  }
  return str;
}

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _homeRepository;

  HomeCubit({required HomeRepository homeRepository})
      : _homeRepository = homeRepository,
        super(const HomeState());

  Future<void> fetchHomeScreenData() async {
    emit(state.copyWith(status: HomeStatus.loading));
    developer.log('HomeCubit: Fetching all home screen data...', name: 'HomeCubit');

    try {
      final results = await Future.wait([
        _homeRepository.getBanners(),
        _homeRepository.getFeaturedCategories(),
        _homeRepository.getFeaturedProducts(),
        _homeRepository.getLatestNewsArticles(),
        _homeRepository.getAllCategories(),
        _homeRepository.getAllProducts(),
      ]);

      List<String> errors = [];

      final finalBanners = (results[0] as Either<Failure, List<BannerModel>>).fold((f) {errors.add(f.message); return <BannerModel>[];}, (r) => r);
      final finalFeaturedCategories = (results[1] as Either<Failure, List<CategoryModel>>).fold((f) {errors.add(f.message); return <CategoryModel>[];}, (r) => r);
      final finalFeaturedProducts = (results[2] as Either<Failure, List<ProductModel>>).fold((f) {errors.add(f.message); return <ProductModel>[];}, (r) => r);
      final finalNews = (results[3] as Either<Failure, List<NewsArticleModel>>).fold((f) {errors.add(f.message); return <NewsArticleModel>[];}, (r) => r);
      final finalAllCategories = (results[4] as Either<Failure, List<CategoryModel>>).fold((f) {errors.add(f.message); return <CategoryModel>[];}, (r) => r);
      final finalAllProducts = (results[5] as Either<Failure, List<ProductModel>>).fold((f) {errors.add(f.message); return <ProductModel>[];}, (r) => r);

      if (errors.isNotEmpty) {
        emit(state.copyWith(status: HomeStatus.error, errorMessage: errors.join('\n')));
      } else {
        emit(state.copyWith(
          status: HomeStatus.success,
          banners: finalBanners,
          categories: finalFeaturedCategories,
          allCategories: finalAllCategories,
          featuredProducts: finalFeaturedProducts,
          filteredFeaturedProducts: finalFeaturedProducts,
          newsArticles: finalNews,
          allProducts: finalAllProducts,
          isSearching: false, // Reset trạng thái tìm kiếm
        ));
      }
    } catch (e) {
      emit(state.copyWith(status: HomeStatus.error, errorMessage: 'Lỗi không xác định: ${e.toString()}'));
    }
  }

  void searchFeaturedProducts(String query) {
    if (query.isEmpty) {
      emit(state.copyWith(
        filteredFeaturedProducts: state.featuredProducts,
        isSearching: false, // Tắt trạng thái tìm kiếm
      ));
      return;
    }

    final normalizedQuery = _removeDiacritics(query.toLowerCase());

    final filtered = state.allProducts.where((product) {
      final normalizedProductName = _removeDiacritics(product.name.toLowerCase());
      final normalizedProductDesc = _removeDiacritics(product.description.toLowerCase());
      return normalizedProductName.contains(normalizedQuery) ||
          normalizedProductDesc.contains(normalizedQuery);
    }).toList();

    developer.log('Searching for "$query", found ${filtered.length} products.', name: 'HomeCubit');

    emit(state.copyWith(
      filteredFeaturedProducts: filtered,
      isSearching: true, // Bật trạng thái tìm kiếm
    ));
  }
}