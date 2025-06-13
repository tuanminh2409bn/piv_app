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
  final String unit;
  final Map<String, double> prices;
  final Map<String, dynamic>? attributes;

  const ProductModel({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '',
    required this.categoryId,
    this.isFeatured = false,
    this.createdAt,
    this.unit = 'sản phẩm',
    this.prices = const {},
    this.attributes,
  });

  // Getter để lấy giá thấp nhất để hiển thị ở danh sách
  double get startingPrice {
    if (prices.isEmpty) return 0.0;
    final sortedPrices = prices.values.toList()..sort();
    return sortedPrices.first;
  }

  // Hàm tiện ích để lấy giá cho một vai trò cụ thể
  double getPriceForRole(String role) {
    return prices[role] ?? 0.0;
  }

  @override
  List<Object?> get props => [
    id, name, description, imageUrl, categoryId,
    isFeatured, createdAt, unit, prices, attributes
  ];

  factory ProductModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>? ?? {};

    Map<String, double> pricesMap = {};
    if (data['prices'] is Map) {
      (data['prices'] as Map).forEach((key, value) {
        if (value is num) {
          pricesMap[key] = value.toDouble();
        }
      });
    }

    return ProductModel(
      id: snap.id,
      name: data['name'] as String? ?? 'N/A',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      isFeatured: data['isFeatured'] as bool? ?? false,
      createdAt: data['createdAt'] as Timestamp?,
      unit: data['unit'] as String? ?? 'sản phẩm',
      prices: pricesMap,
      attributes: data['attributes'] is Map ? Map<String, dynamic>.from(data['attributes']) : null,
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
      'unit': unit,
      'prices': prices,
      'attributes': attributes,
    };
  }
}
