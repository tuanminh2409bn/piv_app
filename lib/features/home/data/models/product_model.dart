import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<String> imageUrls;
  final String categoryId;
  final String categoryName;
  final double basePrice;
  final double? discountPrice;
  final String unit;
  final int stockQuantity;
  final bool isFeatured;
  final Map<String, dynamic>? attributes;
  final Timestamp? createdAt;

  const ProductModel({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrls = const [],
    required this.categoryId,
    this.categoryName = '',
    required this.basePrice,
    this.discountPrice,
    this.unit = 'sản phẩm',
    this.stockQuantity = 0,
    this.isFeatured = false,
    this.attributes,
    this.createdAt,
  });

  double get displayPrice => discountPrice ?? basePrice;

  @override
  List<Object?> get props => [
    id, name, description, imageUrls, categoryId, categoryName,
    basePrice, discountPrice, unit, stockQuantity, isFeatured,
    attributes, createdAt,
  ];

  factory ProductModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>? ?? {};

    List<String> images = [];
    if (data['imageUrls'] is List) {
      images = List<String>.from(data['imageUrls'].map((item) => item.toString())); // Đảm bảo item là string
    } else if (data['imageUrls'] is String) {
      images = [data['imageUrls'] as String];
    }

    // Hàm helper để lấy String an toàn
    String _getString(Map<String, dynamic> data, String key, {String defaultValue = ''}) {
      final value = data[key];
      if (value is String) {
        return value;
      }
      return defaultValue;
    }

    return ProductModel(
      id: snap.id,
      name: _getString(data, 'name', defaultValue: 'N/A'),
      description: _getString(data, 'description'),
      imageUrls: images,
      categoryId: _getString(data, 'categoryId'),
      categoryName: _getString(data, 'categoryName'),
      basePrice: (data['basePrice'] as num? ?? 0).toDouble(),
      discountPrice: (data['discountPrice'] as num?)?.toDouble(),
      unit: _getString(data, 'unit', defaultValue: 'sản phẩm'),
      stockQuantity: (data['stockQuantity'] as num? ?? 0).toInt(),
      isFeatured: data['isFeatured'] as bool? ?? false,
      attributes: data['attributes'] is Map ? Map<String, dynamic>.from(data['attributes']) : null,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'imageUrls': imageUrls,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'basePrice': basePrice,
      'discountPrice': discountPrice,
      'unit': unit,
      'stockQuantity': stockQuantity,
      'isFeatured': isFeatured,
      'attributes': attributes,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
    