import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel extends Equatable {
  final String id; // Document ID từ Firestore
  final String imageUrl;
  final String? targetType; // Ví dụ: 'product', 'category', 'url', 'news'
  final String? targetId;   // ID của sản phẩm, danh mục, tin tức (nếu targetType tương ứng)
  final String? targetUrl;  // URL trực tiếp (nếu targetType là 'url')
  // final int? sortOrder; // Để sắp xếp

  const BannerModel({
    required this.id,
    required this.imageUrl,
    this.targetType,
    this.targetId,
    this.targetUrl,
    // this.sortOrder,
  });

  @override
  List<Object?> get props => [id, imageUrl, targetType, targetId, targetUrl, /*sortOrder*/];

  factory BannerModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>?;
    return BannerModel(
      id: snap.id,
      imageUrl: data?['imageUrl'] as String? ?? '',
      targetType: data?['targetType'] as String?,
      targetId: data?['targetId'] as String?,
      targetUrl: data?['targetUrl'] as String?,
      // sortOrder: data?['sortOrder'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'targetType': targetType,
      'targetId': targetId,
      'targetUrl': targetUrl,
      // 'sortOrder': sortOrder,
    };
  }
}
