part of 'home_cubit.dart';

enum HomeStatus { initial, loading, success, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final List<BannerModel> banners;
  // Danh sách các danh mục nổi bật để hiển thị trên trang chủ
  final List<CategoryModel> categories;
  // Danh sách TẤT CẢ các danh mục để dùng cho các trang khác
  final List<CategoryModel> allCategories;
  final List<ProductModel> featuredProducts;
  final List<NewsArticleModel> newsArticles;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.banners = const [],
    this.categories = const [],
    this.allCategories = const [], // << THÊM TRƯỜNG NÀY VÀO CONSTRUCTOR
    this.featuredProducts = const [],
    this.newsArticles = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
    status,
    banners,
    categories,
    allCategories, // << THÊM VÀO PROPS
    featuredProducts,
    newsArticles,
    errorMessage,
  ];

  HomeState copyWith({
    HomeStatus? status,
    List<BannerModel>? banners,
    List<CategoryModel>? categories,
    List<CategoryModel>? allCategories, // << THÊM VÀO COPYWITH
    List<ProductModel>? featuredProducts,
    List<NewsArticleModel>? newsArticles,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      banners: banners ?? this.banners,
      categories: categories ?? this.categories,
      allCategories: allCategories ?? this.allCategories, // << GÁN GIÁ TRỊ
      featuredProducts: featuredProducts ?? this.featuredProducts,
      newsArticles: newsArticles ?? this.newsArticles,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
