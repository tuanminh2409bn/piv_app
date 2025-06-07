import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/news_article_model.dart'; // Model tin tức thật
import 'package:piv_app/features/home/domain/repositories/home_repository.dart'; // Sử dụng HomeRepository
import 'dart:developer' as developer;

part 'news_detail_state.dart';

class NewsDetailCubit extends Cubit<NewsDetailState> {
  final HomeRepository _homeRepository; // Inject HomeRepository

  NewsDetailCubit({required HomeRepository homeRepository})
      : _homeRepository = homeRepository,
        super(const NewsDetailState()); // Trạng thái ban đầu

  Future<void> fetchNewsArticleDetail(String articleId) async {
    if (articleId.isEmpty) {
      emit(state.copyWith(status: NewsDetailStatus.error, errorMessage: "ID bài viết không hợp lệ."));
      return;
    }
    emit(state.copyWith(status: NewsDetailStatus.loading, clearErrorMessage: true));
    developer.log('NewsDetailCubit: Fetching detail for article ID: $articleId', name: 'NewsDetailCubit');

    final result = await _homeRepository.getNewsArticleById(articleId);

    result.fold(
          (failure) {
        developer.log('NewsDetailCubit: Failed to fetch article detail - ${failure.message}', name: 'NewsDetailCubit');
        emit(state.copyWith(status: NewsDetailStatus.error, errorMessage: failure.message));
      },
          (article) {
        developer.log('NewsDetailCubit: Article detail fetched successfully - ${article.title}', name: 'NewsDetailCubit');
        emit(state.copyWith(status: NewsDetailStatus.success, article: article));
      },
    );
  }
}
