import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class CategoryModel extends Equatable {
  final String id; // Document ID từ Firestore
  final String name;
  final String imageUrl;
  // Bạn có thể thêm các trường khác nếu cần, ví dụ:
  // final int? sortOrder; // Để sắp xếp thứ tự hiển thị

  const CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    // this.sortOrder,
  });

  @override
  List<Object?> get props => [id, name, imageUrl, /*sortOrder*/];

  // Factory constructor để tạo CategoryModel từ một DocumentSnapshot (Firestore)
  factory CategoryModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>?; // Ép kiểu an toàn
    return CategoryModel(
      id: snap.id,
      name: data?['name'] as String? ?? '', // Xử lý null với giá trị mặc định
      imageUrl: data?['imageUrl'] as String? ?? '',
      // sortOrder: data?['sortOrder'] as int?,
    );
  }

  // Phương thức để chuyển CategoryModel thành Map để lưu vào Firestore (nếu cần)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      // 'sortOrder': sortOrder,
    };
  }
}
