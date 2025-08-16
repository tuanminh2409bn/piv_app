// lib/data/models/order_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/address_model.dart';
import 'package:piv_app/data/models/order_item_model.dart';

// Lớp mới để lưu thông tin người đặt hộ (An toàn vì không thay đổi code cũ)
class PlacedByInfo extends Equatable {
  final String userId;
  final String role;

  const PlacedByInfo({required this.userId, required this.role});

  Map<String, dynamic> toMap() => {'userId': userId, 'role': role};

  factory PlacedByInfo.fromMap(Map<String, dynamic> map) {
    return PlacedByInfo(
      userId: map['userId'] ?? '',
      role: map['role'] ?? '',
    );
  }

  @override
  List<Object?> get props => [userId, role];
}

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
  final String status; // Giữ nguyên là String
  final Timestamp? createdAt;
  final String? salesRepId;
  final double commissionDiscount;
  final double finalTotal;

  // --- CÁC TRƯỜNG MỚI CHO TÍNH NĂNG "ĐẶT HỘ" ---
  final PlacedByInfo? placedBy;
  final Timestamp? approvedAt;
  final Timestamp? rejectedAt;
  final String? rejectionReason;
  // ------------------------------------------

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
    // Thêm các trường mới
    this.placedBy,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
  });

  @override
  List<Object?> get props => [
    id, userId, items, shippingAddress, subtotal, shippingFee, discount, total,
    paymentMethod, paymentStatus, status, createdAt, salesRepId, commissionDiscount, finalTotal,
    placedBy, approvedAt, rejectedAt, rejectionReason
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
      'paymentStatus': paymentStatus,
      'status': status,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'salesRepId': salesRepId,
      'commissionDiscount': commissionDiscount,
      'finalTotal': finalTotal,
      // Thêm các trường mới
      'placedBy': placedBy?.toMap(),
      'approvedAt': approvedAt,
      'rejectedAt': rejectedAt,
      'rejectionReason': rejectionReason,
    };
  }

  factory OrderModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    // ... (logic cũ giữ nguyên)

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
      paymentMethod: data['paymentMethod'] ?? 'COD',
      paymentStatus: data['paymentStatus'] ?? 'unpaid',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] as Timestamp?,
      salesRepId: data['salesRepId'] as String?,
      commissionDiscount: (data['commissionDiscount'] as num?)?.toDouble() ?? 0.0,
      finalTotal: (data['finalTotal'] as num?)?.toDouble() ?? 0.0,
      // Đọc dữ liệu cho các trường mới
      placedBy: data['placedBy'] != null
          ? PlacedByInfo.fromMap(data['placedBy'] as Map<String, dynamic>)
          : null,
      approvedAt: data['approvedAt'] as Timestamp?,
      rejectedAt: data['rejectedAt'] as Timestamp?,
      rejectionReason: data['rejectionReason'] as String?,
    );
  }
}