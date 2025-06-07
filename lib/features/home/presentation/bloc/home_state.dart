part of 'home_cubit.dart';

enum HomeStatus {
  initial,
  loading,
  success,
  error,
}

// KHÔNG CÓ BẤT KỲ LỆNH IMPORT NÀO Ở ĐÂY

// XÓA ĐỊNH NGHĨA NewsArticleModel GIẢ Ở ĐÂY (NẾU CÓ)
// class NewsArticleModel extends Equatable {
//   final String id;
//   final String title;
//   final String summary;
//   final String imageUrl;
//   const NewsArticleModel({required this.id, required this.title, required this.summary, required this.imageUrl});
//   @override List<Object?> get props => [id, title, summary, imageUrl];
// }


class HomeState extends Equatable {
  final HomeStatus status;
  // Các kiểu BannerModel, CategoryModel, ProductModel, NewsArticleModel ở đây
  // sẽ là các kiểu được import trong file home_cubit.dart (là các model thật)
  final List<BannerModel> banners;
  final List<CategoryModel> categories;
  final List<ProductModel> featuredProducts;
  final List<NewsArticleModel> newsArticles; // Sẽ sử dụng NewsArticleModel thật
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.banners = const [],
    this.categories = const [],
    this.featuredProducts = const [],
    this.newsArticles = const [],
    this.errorMessage,
  });

  HomeState copyWith({
    HomeStatus? status,
    List<BannerModel>? banners,
    List<CategoryModel>? categories,
    List<ProductModel>? featuredProducts,
    List<NewsArticleModel>? newsArticles, // Sẽ sử dụng NewsArticleModel thật
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      banners: banners ?? this.banners,
      categories: categories ?? this.categories,
      featuredProducts: featuredProducts ?? this.featuredProducts,
      newsArticles: newsArticles ?? this.newsArticles,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    banners,
    categories,
    featuredProducts,
    newsArticles,
    errorMessage,
  ];
}
