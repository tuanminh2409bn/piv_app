import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final Timestamp? createdAt; // << SỬA: Cho phép trường này có thể null

  const OrderModel({
    this.id,
    required this.userId,
    required this.items,
    required this.shippingAddress,
    required this.subtotal,
    this.shippingFee = 0.0,
    this.discount = 0.0,
    required this.total,
    this.paymentMethod = 'COD',
    this.status = 'pending',
    this.createdAt, // << SỬA: Không còn là 'required' nữa
  });

  @override
  List<Object?> get props => [id, userId, items, shippingAddress, subtotal, shippingFee, discount, total, paymentMethod, status, createdAt];

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
      // ** SỬA: Nếu createdAt chưa có (khi tạo mới), dùng server timestamp.
      // Nếu có rồi (khi đọc từ DB), giữ nguyên.
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
