import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/address_model.dart';
import 'package:piv_app/data/models/order_item_model.dart';

class OrderModel extends Equatable {
  final String? id;
  final String userId;
  final List<OrderItemModel> items;
  final AddressModel shippingAddress;
  final double subtotal;
  final double shippingFee;
  final double discount;
  final double total;
  final String paymentMethod;
  final String status;
  final Timestamp? createdAt;
  final String? salesRepId; // ID của NVKD phụ trách

  const OrderModel({
    this.id,
    required this.userId,
    required this.items,
    required this.shippingAddress,
    required this.subtotal,
    required this.shippingFee,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.status,
    this.createdAt,
    this.salesRepId,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    items,
    shippingAddress,
    subtotal,
    shippingFee,
    discount,
    total,
    paymentMethod,
    status,
    createdAt,
    salesRepId,
  ];

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'shippingAddress': shippingAddress.toMap(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'salesRepId': salesRepId,
    };
  }

  factory OrderModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    return OrderModel(
      id: snap.id,
      userId: data['userId'] ?? '',
      items: (data['items'] as List<dynamic>)
          .map((itemData) =>
          OrderItemModel.fromMap(itemData as Map<String, dynamic>))
          .toList(),
      shippingAddress:
      AddressModel.fromMap(data['shippingAddress'] as Map<String, dynamic>),
      subtotal: (data['subtotal'] as num).toDouble(),
      shippingFee: (data['shippingFee'] as num).toDouble(),
      discount: (data['discount'] as num).toDouble(),
      total: (data['total'] as num).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'N/A',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] as Timestamp?,
      salesRepId: data['salesRepId'] as String?,
    );
  }
}