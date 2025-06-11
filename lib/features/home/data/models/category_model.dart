import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel extends Equatable {
  final String id;
  final String name;
  final String imageUrl;
  final String? parentId; // Có thể null cho danh mục gốc

  const CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.parentId,
  });

  @override
  List<Object?> get props => [id, name, imageUrl, parentId];

  factory CategoryModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>?;
    return CategoryModel(
      id: snap.id,
      name: data?['name'] as String? ?? '',
      imageUrl: data?['imageUrl'] as String? ?? '',
      parentId: data?['parentId'] as String?, // Đọc parentId từ Firestore
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'parentId': parentId,
    };
  }
}
