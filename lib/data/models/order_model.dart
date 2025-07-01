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
  final String paymentStatus;
  final String status;
  final Timestamp? createdAt;
  final String? salesRepId;
  final double commissionDiscount;
  final double finalTotal;

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
    this.paymentStatus = 'unpaid',
    required this.status,
    this.createdAt,
    this.salesRepId,
    this.commissionDiscount = 0.0,
    this.finalTotal = 0.0,
  });

  @override
  List<Object?> get props => [
    id, userId, items, shippingAddress, subtotal, shippingFee, discount, total,
    paymentMethod, paymentStatus, status, createdAt, salesRepId, commissionDiscount, finalTotal,
  ];

  // HÀM NÀY RẤT QUAN TRỌNG
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
      'paymentStatus': paymentStatus,
      'status': status,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'salesRepId': salesRepId,
      'commissionDiscount': commissionDiscount, // PHẢI CÓ DÒNG NÀY
      'finalTotal': finalTotal,             // PHẢI CÓ DÒNG NÀY
    };
  }

  factory OrderModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    final initialTotal = (data['total'] as num?)?.toDouble() ?? 0.0;
    final commissionDiscountValue = (data['commissionDiscount'] as num?)?.toDouble() ?? 0.0;

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
      total: initialTotal,
      paymentMethod: data['paymentMethod'] ?? 'COD',
      paymentStatus: data['paymentStatus'] ?? 'unpaid',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] as Timestamp?,
      salesRepId: data['salesRepId'] as String?,
      commissionDiscount: commissionDiscountValue,
      finalTotal: (data['finalTotal'] as num?)?.toDouble() ?? (initialTotal - commissionDiscountValue),
    );
  }
}