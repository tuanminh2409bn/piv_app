// lib/data/models/news_article_model.dart
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewsArticleModel extends Equatable {
  final String id;
  final String title;
  final String summary;
  final String content;
  final String imageUrl;
  final String? author;
  final Timestamp publishedDate;
  final String? sourceUrl;

  const NewsArticleModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.imageUrl,
    this.author,
    required this.publishedDate,
    this.sourceUrl,
  });

  @override
  List<Object?> get props => [id, title, summary, content, imageUrl, author, publishedDate, sourceUrl];

  factory NewsArticleModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>? ?? {};
    return NewsArticleModel(
      id: snap.id,
      title: data['title'] as String? ?? 'Chưa có tiêu đề',
      summary: data['summary'] as String? ?? '',
      content: data['content'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      author: data['author'] as String?,
      publishedDate: data['publishedDate'] as Timestamp? ?? Timestamp.now(),
      sourceUrl: data['sourceUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'summary': summary,
      'content': content,
      'imageUrl': imageUrl,
      'author': author,
      'publishedDate': publishedDate,
      'sourceUrl': sourceUrl,
    };
  }

  // ✅ ADDING THIS METHOD FIXES MANY ERRORS
  NewsArticleModel copyWith({
    String? id,
    String? title,
    String? summary,
    String? content,
    String? imageUrl,
    String? author,
    Timestamp? publishedDate,
    String? sourceUrl,
  }) {
    return NewsArticleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      author: author ?? this.author,
      publishedDate: publishedDate ?? this.publishedDate,
      sourceUrl: sourceUrl ?? this.sourceUrl,
    );
  }
}