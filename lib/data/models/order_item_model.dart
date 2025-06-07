import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/cart_item_model.dart';

class OrderItemModel extends Equatable {
  final String productId;
  final String productName;
  final String imageUrl;
  final double price; // Giá tại thời điểm đặt hàng
  final String unit;
  final int quantity;

  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.unit,
    required this.quantity,
  });

  @override
  List<Object?> get props => [productId, productName, imageUrl, price, unit, quantity];

  // Tiện ích để chuyển đổi từ một CartItemModel
  factory OrderItemModel.fromCartItem(CartItemModel cartItem) {
    return OrderItemModel(
      productId: cartItem.productId,
      productName: cartItem.productName,
      imageUrl: cartItem.imageUrl,
      price: cartItem.price,
      unit: cartItem.unit,
      quantity: cartItem.quantity,
    );
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? 'N/A',
      imageUrl: map['imageUrl'] as String? ?? '',
      price: (map['price'] as num? ?? 0).toDouble(),
      unit: map['unit'] as String? ?? '',
      quantity: (map['quantity'] as num? ?? 0).toInt(),
    );
  }

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
