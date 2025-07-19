// lib/features/admin/presentation/bloc/news_form_state.dart
part of 'news_form_cubit.dart';

enum NewsFormStatus { initial, editing, saving, success, error }

class NewsFormState extends Equatable {
  final NewsArticleModel article;
  final NewsFormStatus status;
  final String? errorMessage;

  const NewsFormState({
    required this.article,
    this.status = NewsFormStatus.initial,
    this.errorMessage,
  });

  // ✅ CORRECTED TO MATCH YOUR MODEL
  factory NewsFormState.initial() => NewsFormState(
      article: NewsArticleModel(
          id: 'new', // Temporary ID for a new article
          title: '', summary: '', content: '', imageUrl: '', publishedDate: Timestamp.now()
      )
  );

  NewsFormState copyWith({
    NewsArticleModel? article,
    NewsFormStatus? status,
    String? errorMessage,
  }) {
    return NewsFormState(
      article: article ?? this.article,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [article, status, errorMessage];
}