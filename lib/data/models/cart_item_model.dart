import 'package:equatable/equatable.dart';

class CartItemModel extends Equatable {
  final String productId;
  final String productName;
  final String imageUrl;
  final double price;
  final String itemUnitName;
  final int quantity;
  final int quantityPerPackage; // THỐNG NHẤT SỬ DỤNG TÊN NÀY
  final String caseUnitName;

  const CartItemModel({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.itemUnitName,
    required this.quantity,
    required this.quantityPerPackage,
    required this.caseUnitName,
  });

  double get subtotal => price * quantityPerPackage * quantity;

  CartItemModel copyWith({int? quantity}) {
    return CartItemModel(
      productId: this.productId,
      productName: this.productName,
      imageUrl: this.imageUrl,
      price: this.price,
      itemUnitName: this.itemUnitName,
      quantity: quantity ?? this.quantity,
      quantityPerPackage: this.quantityPerPackage,
      caseUnitName: this.caseUnitName,
    );
  }

  @override
  List<Object?> get props => [productId, productName, imageUrl, price, itemUnitName, quantity, quantityPerPackage, caseUnitName];

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? 'N/A',
      imageUrl: map['imageUrl'] as String? ?? '',
      price: (map['price'] as num? ?? 0).toDouble(),
      itemUnitName: map['itemUnitName'] as String? ?? 'sản phẩm',
      quantity: (map['quantity'] as num? ?? 0).toInt(),
      quantityPerPackage: (map['quantityPerPackage'] as num? ?? 1).toInt(),
      caseUnitName: map['caseUnitName'] as String? ?? 'thùng',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'price': price,
      'itemUnitName': itemUnitName,
      'quantity': quantity,
      'quantityPerPackage': quantityPerPackage,
      'caseUnitName': caseUnitName,
    };
  }
}