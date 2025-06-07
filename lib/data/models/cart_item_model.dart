import 'package:equatable/equatable.dart';

class CartItemModel extends Equatable {
  final String productId;
  final String productName;
  final String imageUrl; // Ảnh đại diện của sản phẩm
  final double price;    // Giá tại thời điểm thêm vào giỏ
  final String unit;     // Đơn vị tính
  final int quantity;

  const CartItemModel({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.unit,
    required this.quantity,
  });

  // copyWith để dễ dàng cập nhật số lượng
  CartItemModel copyWith({
    int? quantity,
  }) {
    return CartItemModel(
      productId: this.productId,
      productName: this.productName,
      imageUrl: this.imageUrl,
      price: this.price,
      unit: this.unit,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [productId, productName, imageUrl, price, unit, quantity];

  // Chuyển đổi từ Map (dữ liệu đọc từ Firestore) thành CartItemModel
  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? 'N/A',
      imageUrl: map['imageUrl'] as String? ?? '',
      price: (map['price'] as num? ?? 0).toDouble(),
      unit: map['unit'] as String? ?? '',
      quantity: (map['quantity'] as num? ?? 0).toInt(),
    );
  }

  // Chuyển đổi CartItemModel thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'price': price,
      'unit': unit,
      'quantity': quantity,
    };
  }
}
