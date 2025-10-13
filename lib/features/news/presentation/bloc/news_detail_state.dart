part of 'news_detail_cubit.dart'; // Sẽ tạo file news_detail_cubit.dart sau

enum NewsDetailStatus {
  initial, // Trạng thái ban đầu
  loading, // Đang tải chi tiết bài viết
  success, // Tải thành công
  error,   // Có lỗi xảy ra
}

class NewsDetailState extends Equatable {
  final NewsDetailStatus status;
  final NewsArticleModel? article; // Bài viết chi tiết, có thể null ban đầu hoặc khi lỗi
  final String? errorMessage;

  const NewsDetailState({
    this.status = NewsDetailStatus.initial,
    this.article,
    this.errorMessage,
  });

  NewsDetailState copyWith({
    NewsDetailStatus? status,
    NewsArticleModel? article,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return NewsDetailState(
      status: status ?? this.status,
      article: article ?? this.article, // Giữ lại article cũ nếu article mới là null và không có ý định xóa
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  // Hàm tiện ích để xóa article khi cần (ví dụ khi tải lại hoặc lỗi nặng)
  NewsDetailState resetArticle() {
    return NewsDetailState(
      status: this.status, // Giữ lại status hiện tại hoặc đặt lại nếu cần
      article: null,
      errorMessage: this.errorMessage,
    );
  }


  @override
  List<Object?> get props => [status, article, errorMessage];
}
