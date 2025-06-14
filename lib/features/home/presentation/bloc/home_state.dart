part of 'home_cubit.dart';

enum HomeStatus { initial, loading, success, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final List<BannerModel> banners;
  // Danh sách các danh mục gốc để hiển thị trên trang chủ
  final List<CategoryModel> categories;
  // Danh sách TẤT CẢ các danh mục để dùng cho các trang khác
  final List<CategoryModel> allCategories;
  // Danh sách gốc của sản phẩm nổi bật
  final List<ProductModel> featuredProducts;
  // Danh sách sản phẩm nổi bật đã được lọc để hiển thị
  final List<ProductModel> filteredFeaturedProducts;
  final List<NewsArticleModel> newsArticles;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.banners = const [],
    this.categories = const [],
    this.allCategories = const [],
    this.featuredProducts = const [],
    this.filteredFeaturedProducts = const [],
    this.newsArticles = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
    status,
    banners,
    categories,
    allCategories,
    featuredProducts,
    filteredFeaturedProducts,
    newsArticles,
    errorMessage,
  ];

  HomeState copyWith({
    HomeStatus? status,
    List<BannerModel>? banners,
    List<CategoryModel>? categories,
    List<CategoryModel>? allCategories,
    List<ProductModel>? featuredProducts,
    List<ProductModel>? filteredFeaturedProducts,
    List<NewsArticleModel>? newsArticles,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      banners: banners ?? this.banners,
      categories: categories ?? this.categories,
      allCategories: allCategories ?? this.allCategories,
      featuredProducts: featuredProducts ?? this.featuredProducts,
      filteredFeaturedProducts:
      filteredFeaturedProducts ?? this.filteredFeaturedProducts,
      newsArticles: newsArticles ?? this.newsArticles,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}