// lib/features/home/data/models/product_model.dart

import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:piv_app/data/models/packaging_option_model.dart';

class ProductModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String categoryId;
  final bool isFeatured;
  final Timestamp? createdAt;
  final Map<String, dynamic>? attributes;

  // --- SỬA TÊN TRƯỜNG TẠI ĐÂY ---
  final List<PackagingOptionModel> packingOptions;
  // -----------------------------

  const ProductModel({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '',
    required this.categoryId,
    this.isFeatured = false,
    this.createdAt,
    this.attributes,
    this.packingOptions = const [], // Sửa tên trường
  });

  double getPriceForRole(String role) {
    if (packingOptions.isEmpty) return 0.0; // Sửa tên trường
    return packingOptions.first.getPriceForRole(role); // Sửa tên trường
  }

  String get displayUnit {
    if (packingOptions.isEmpty) return 'sản phẩm'; // Sửa tên trường
    return packingOptions.first.unit; // Sửa tên trường
  }

  @override
  List<Object?> get props => [
    id, name, description, imageUrl, categoryId,
    isFeatured, createdAt, attributes, packingOptions // Sửa tên trường
  ];

  factory ProductModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>? ?? {};

    // --- SỬA TÊN TRƯỜNG KHI ĐỌC TỪ FIRESTORE ---
    final optionsList = (data['packingOptions'] as List<dynamic>?)
        ?.map((optionMap) => PackagingOptionModel.fromMap(optionMap as Map<String, dynamic>))
        .toList() ?? [];
    // ------------------------------------------

    return ProductModel(
      id: snap.id,
      name: data['name'] as String? ?? 'N/A',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      isFeatured: data['isFeatured'] as bool? ?? false,
      createdAt: data['createdAt'] as Timestamp?,
      attributes: data['attributes'] is Map ? Map<String, dynamic>.from(data['attributes']) : null,
      packingOptions: optionsList, // Sửa tên trường
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
      'attributes': attributes,
      // --- SỬA TÊN TRƯỜNG KHI LƯU LÊN FIRESTORE ---
      'packingOptions': packingOptions.map((option) => option.toMap()).toList(),
      // ------------------------------------------
    };
  }
}