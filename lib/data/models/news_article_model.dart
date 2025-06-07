import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewsArticleModel extends Equatable {
  final String id; // Document ID từ Firestore
  final String title;
  final String summary; // Mô tả ngắn
  final String content; // Nội dung đầy đủ (có thể là HTML hoặc Markdown)
  final String imageUrl; // URL ảnh đại diện
  final String? author;
  final Timestamp publishedDate;
  final String? sourceUrl; // Link tới bài viết gốc (nếu có)
  // final List<String>? tags; // Bạn có thể thêm trường này nếu cần

  const NewsArticleModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.imageUrl,
    this.author,
    required this.publishedDate,
    this.sourceUrl,
    // this.tags,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    summary,
    content,
    imageUrl,
    author,
    publishedDate,
    sourceUrl,
    // tags,
  ];

  // Factory constructor để tạo NewsArticleModel từ một DocumentSnapshot (Firestore)
  factory NewsArticleModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>? ?? {}; // Đảm bảo data không bao giờ null

    return NewsArticleModel(
      id: snap.id,
      title: data['title'] as String? ?? 'N/A', // Xử lý null với giá trị mặc định
      summary: data['summary'] as String? ?? '',
      content: data['content'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      author: data['author'] as String?, // Có thể null
      publishedDate: data['publishedDate'] as Timestamp? ?? Timestamp.now(), // Giá trị mặc định nếu null
      sourceUrl: data['sourceUrl'] as String?, // Có thể null
      // tags: (data['tags'] as List<dynamic>?)?.map((e) => e as String).toList(), // Xử lý cho list (nếu có)
    );
  }

  // Phương thức để chuyển NewsArticleModel thành Map để lưu vào Firestore (nếu cần tạo/cập nhật)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'summary': summary,
      'content': content,
      'imageUrl': imageUrl,
      'author': author,
      'publishedDate': publishedDate,
      'sourceUrl': sourceUrl,
      // 'tags': tags,
    };
  }
}
