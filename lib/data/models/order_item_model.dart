//lib/data/models/order_item_model.dart

import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/cart_item_model.dart';

class OrderItemModel extends Equatable {
  final String productId;
  final String productName;
  final String imageUrl;
  final double price;
  final int quantity;
  final int confirmedQuantity; // Số thùng/gói thực giao
  final int confirmedLooseQuantity; // <<< THÊM MỚI: Số lượng lẻ thực giao
  final String unit;
  final String packaging;
  final int quantityPerPackage;

  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    this.confirmedQuantity = 0,
    this.confirmedLooseQuantity = 0, // Mặc định là 0
    required this.unit,
    required this.packaging,
    required this.quantityPerPackage,
  });

  // Tiền tạm tính dựa trên số lượng đặt ban đầu
  double get subtotal => price * quantityPerPackage * quantity;
  
  // Tiền thực tế dựa trên số lượng công ty xác nhận trả hàng (Thùng + Lẻ)
  double get confirmedSubtotal {
    final totalUnits = (confirmedQuantity * quantityPerPackage) + confirmedLooseQuantity;
    return price * totalUnits;
  }

  @override
  List<Object?> get props => [
    productId,
    productName,
    imageUrl,
    price,
    quantity,
    confirmedQuantity,
    confirmedLooseQuantity,
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
      'confirmedQuantity': confirmedQuantity,
      'confirmedLooseQuantity': confirmedLooseQuantity,
      'unit': unit,
      'packaging': packaging,
      'quantityPerPackage': quantityPerPackage,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    final qty = (map['quantity'] as num? ?? 0).toInt();
    return OrderItemModel(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] as num? ?? 0).toDouble(),
      quantity: qty,
      confirmedQuantity: (map['confirmedQuantity'] as num? ?? qty).toInt(),
      confirmedLooseQuantity: (map['confirmedLooseQuantity'] as num? ?? 0).toInt(),
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
      confirmedQuantity: cartItem.quantity,
      confirmedLooseQuantity: 0,
      unit: cartItem.itemUnitName,
      packaging: cartItem.caseUnitName,
      quantityPerPackage: cartItem.quantityPerPackage,
    );
  }

  OrderItemModel copyWith({
    String? productId,
    String? productName,
    String? imageUrl,
    double? price,
    int? quantity,
    int? confirmedQuantity,
    int? confirmedLooseQuantity,
    String? unit,
    String? packaging,
    int? quantityPerPackage,
  }) {
    return OrderItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      confirmedQuantity: confirmedQuantity ?? this.confirmedQuantity,
      confirmedLooseQuantity: confirmedLooseQuantity ?? this.confirmedLooseQuantity,
      unit: unit ?? this.unit,
      packaging: packaging ?? this.packaging,
      quantityPerPackage: quantityPerPackage ?? this.quantityPerPackage,
    );
  }
}