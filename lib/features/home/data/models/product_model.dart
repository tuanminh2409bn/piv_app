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
  final List<PackagingOptionModel> packingOptions;
  final String? productType;
  final bool isPrivate;
  final String? ownerAgentId;

  const ProductModel({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '',
    required this.categoryId,
    this.isFeatured = false,
    this.createdAt,
    this.attributes,
    this.packingOptions = const [],
    this.productType,
    this.isPrivate = false,
    this.ownerAgentId,
  });

  double getPriceForRole(String role) {
    if (packingOptions.isEmpty) return 0.0;
    return packingOptions.first.getPriceForRole(role);
  }

  String get displayUnit {
    if (packingOptions.isEmpty) return 'sản phẩm';
    return packingOptions.first.unit;
  }

  @override
  List<Object?> get props => [
    id, name, description, imageUrl, categoryId,
    isFeatured, createdAt, attributes, packingOptions,
    productType, isPrivate, ownerAgentId
  ];

  factory ProductModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>? ?? {};

    final optionsList = (data['packingOptions'] as List<dynamic>?)
        ?.map((optionMap) => PackagingOptionModel.fromMap(optionMap as Map<String, dynamic>))
        .toList() ?? [];

    return ProductModel(
      id: snap.id,
      name: data['name'] as String? ?? 'N/A',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      isFeatured: data['isFeatured'] as bool? ?? false,
      createdAt: data['createdAt'] as Timestamp?,
      attributes: data['attributes'] is Map ? Map<String, dynamic>.from(data['attributes']) : null,
      packingOptions: optionsList,
      productType: data['productType'] as String?,
      isPrivate: data['isPrivate'] as bool? ?? false,
      ownerAgentId: data['ownerAgentId'] as String?,
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
      'packingOptions': packingOptions.map((option) => option.toMap()).toList(),
      'productType': productType,
      'isPrivate': isPrivate,
      'ownerAgentId': ownerAgentId,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? categoryId,
    bool? isFeatured,
    Timestamp? createdAt,
    Map<String, dynamic>? attributes,
    List<PackagingOptionModel>? packingOptions,
    String? productType,
    bool? isPrivate,
    String? ownerAgentId,
    bool clearOwnerAgentId = false,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      attributes: attributes ?? this.attributes,
      packingOptions: packingOptions ?? this.packingOptions,
      productType: productType ?? this.productType,
      isPrivate: isPrivate ?? this.isPrivate,
      ownerAgentId: clearOwnerAgentId ? null : (ownerAgentId ?? this.ownerAgentId),
    );
  }
}