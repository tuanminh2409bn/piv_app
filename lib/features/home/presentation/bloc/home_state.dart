part of 'home_cubit.dart';

enum HomeStatus { initial, loading, success, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final List<BannerModel> banners;
  final List<CategoryModel> categories;
  final List<CategoryModel> allCategories;
  final List<ProductModel> featuredProducts;
  final List<ProductModel> filteredFeaturedProducts;
  final List<ProductModel> allProducts;
  final List<NewsArticleModel> newsArticles;
  final String? errorMessage;
  final bool isSearching;
  final UserModel? user; // <<< THÊM TRƯỜNG NÀY

  const HomeState({
    this.status = HomeStatus.initial,
    this.banners = const [],
    this.categories = const [],
    this.allCategories = const [],
    this.featuredProducts = const [],
    this.filteredFeaturedProducts = const [],
    this.allProducts = const [],
    this.newsArticles = const [],
    this.errorMessage,
    this.isSearching = false,
    this.user, // <<< THÊM VÀO CONSTRUCTOR
  });

  @override
  List<Object?> get props => [
    status, banners, categories, allCategories, featuredProducts,
    filteredFeaturedProducts, newsArticles, errorMessage, isSearching, allProducts,
    user, // <<< THÊM VÀO PROPS
  ];

  HomeState copyWith({
    HomeStatus? status,
    List<BannerModel>? banners,
    List<CategoryModel>? categories,
    List<CategoryModel>? allCategories,
    List<ProductModel>? featuredProducts,
    List<ProductModel>? filteredFeaturedProducts,
    List<ProductModel>? allProducts,
    List<NewsArticleModel>? newsArticles,
    String? errorMessage,
    bool? isSearching,
    UserModel? user, // <<< THÊM VÀO COPYWITH
  }) {
    return HomeState(
      status: status ?? this.status,
      banners: banners ?? this.banners,
      categories: categories ?? this.categories,
      allCategories: allCategories ?? this.allCategories,
      featuredProducts: featuredProducts ?? this.featuredProducts,
      filteredFeaturedProducts: filteredFeaturedProducts ?? this.filteredFeaturedProducts,
      allProducts: allProducts ?? this.allProducts,
      newsArticles: newsArticles ?? this.newsArticles,
      errorMessage: errorMessage ?? this.errorMessage,
      isSearching: isSearching ?? this.isSearching,
      user: user ?? this.user,
    );
  }
}