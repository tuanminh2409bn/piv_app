import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/cart_item_model.dart';

class OrderItemModel extends Equatable {
  final String productId;
  final String productName;
  final String imageUrl;
  final double price;
  final int quantity;
  final String unit;
  final String packaging;
  final int quantityPerPackage;

  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.packaging,
    required this.quantityPerPackage,
  });

  double get subtotal => price * quantityPerPackage * quantity;

  @override
  List<Object?> get props => [
    productId,
    productName,
    imageUrl,
    price,
    quantity,
    unit,
    packaging,
    quantityPerPackage,
  ];

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'packaging': packaging,
      'quantityPerPackage': quantityPerPackage,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] as num? ?? 0).toDouble(),
      quantity: (map['quantity'] as num? ?? 0).toInt(),
      unit: map['unit'] ?? 'sản phẩm',
      packaging: map['packaging'] ?? '',
      quantityPerPackage: (map['quantityPerPackage'] as num? ?? 1).toInt(),
    );
  }

  factory OrderItemModel.fromCartItem(CartItemModel cartItem) {
    return OrderItemModel(
      productId: cartItem.productId,
      productName: cartItem.productName,
      imageUrl: cartItem.imageUrl,
      price: cartItem.price,
      quantity: cartItem.quantity,
      unit: cartItem.itemUnitName,
      packaging: '${cartItem.quantity} x ${cartItem.caseUnitName}',
      quantityPerPackage: cartItem.quantityPerPackage,
    );
  }
}