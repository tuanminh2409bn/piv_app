import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String categoryId;
  final bool isFeatured;
  final Timestamp? createdAt;
  final double basePrice;
  final double? discountPrice;
  final String unit;
  // ** THÊM TRƯỜNG NÀY **
  final Map<String, dynamic>? attributes;

  const ProductModel({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '',
    required this.categoryId,
    this.isFeatured = false,
    this.createdAt,
    required this.basePrice,
    this.discountPrice,
    this.unit = 'sản phẩm',
    this.attributes, // << THÊM VÀO CONSTRUCTOR
  });

  double get displayPrice => discountPrice ?? basePrice;

  @override
  List<Object?> get props => [
    id, name, description, imageUrl, categoryId,
    isFeatured, createdAt, basePrice, discountPrice, unit,
    attributes, // << THÊM VÀO PROPS
  ];

  factory ProductModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>? ?? {};

    return ProductModel(
      id: snap.id,
      name: data['name'] as String? ?? 'N/A',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      isFeatured: data['isFeatured'] as bool? ?? false,
      createdAt: data['createdAt'] as Timestamp?,
      basePrice: (data['basePrice'] as num? ?? 0).toDouble(),
      discountPrice: (data['discountPrice'] as num?)?.toDouble(),
      unit: data['unit'] as String? ?? 'sản phẩm',
      // ** ĐỌC DỮ LIỆU ATTRIBUTES TỪ FIRESTORE **
      attributes: data['attributes'] is Map
          ? Map<String, dynamic>.from(data['attributes'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'isFeatured': isFeatured,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'basePrice': basePrice,
      'discountPrice': discountPrice,
      'unit': unit,
      'attributes': attributes, // << THÊM VÀO KHI LƯU
    };
  }
}
