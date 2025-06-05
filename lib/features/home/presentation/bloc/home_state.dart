part of 'home_cubit.dart';

enum HomeStatus {
  initial,
  loading,
  success,
  error,
}

// KHÔNG CÓ BẤT KỲ LỆNH IMPORT NÀO Ở ĐÂY

// XÓA ĐỊNH NGHĨA ProductModel GIẢ Ở ĐÂY
// class ProductModel extends Equatable {
//   final String id;
//   final String name;
//   final String imageUrl;
//   final String price;
//   const ProductModel({required this.id, required this.name, required this.imageUrl, required this.price});
//   @override List<Object?> get props => [id, name, imageUrl, price];
// }


// Giữ lại NewsArticleModel giả nếu bạn vẫn đang dùng nó
class NewsArticleModel extends Equatable {
  final String id;
  final String title;
  final String summary;
  final String imageUrl;
  const NewsArticleModel({required this.id, required this.title, required this.summary, required this.imageUrl});
  @override List<Object?> get props => [id, title, summary, imageUrl];
}


class HomeState extends Equatable {
  final HomeStatus status;
  // Kiểu BannerModel, CategoryModel, ProductModel ở đây sẽ là kiểu được import trong home_cubit.dart
  final List<BannerModel> banners;
  final List<CategoryModel> categories;
  final List<ProductModel> featuredProducts; // Sẽ sử dụng ProductModel thật
  final List<NewsArticleModel> newsArticles; // Vẫn là model giả
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
    List<ProductModel>? featuredProducts, // Sẽ sử dụng ProductModel thật
    List<NewsArticleModel>? newsArticles,
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
