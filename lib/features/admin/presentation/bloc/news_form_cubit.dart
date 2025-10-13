// lib/features/admin/presentation/bloc/news_form_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:piv_app/data/models/news_article_model.dart';

part 'news_form_state.dart';

class NewsFormCubit extends Cubit<NewsFormState> {
  NewsFormCubit() : super(NewsFormState.initial());

  void loadArticle(NewsArticleModel? article) {
    if (article != null) {
      emit(state.copyWith(article: article, status: NewsFormStatus.editing));
    }
  }

  // ✅ CORRECTED TO MATCH YOUR MODEL'S FIELDS
  void updateField({String? title, String? summary, String? content, String? imageUrl}) {
    emit(state.copyWith(
      article: state.article.copyWith(
        title: title,
        summary: summary,
        content: content,
        imageUrl: imageUrl,
      ),
    ));
  }

  Future<void> saveArticle() async {
    emit(state.copyWith(status: NewsFormStatus.saving));
    try {
      final articleToSave = state.article.copyWith(
        publishedDate: Timestamp.now(), // Always update the date on save
      );

      if (articleToSave.id == 'new') {
        await FirebaseFirestore.instance.collection('newsArticles').add(articleToSave.toJson());
      } else {
        await FirebaseFirestore.instance.collection('newsArticles').doc(articleToSave.id).update(articleToSave.toJson());
      }
      emit(state.copyWith(status: NewsFormStatus.success));
    } catch (e) {
      emit(state.copyWith(status: NewsFormStatus.error, errorMessage: e.toString()));
    }
  }
}