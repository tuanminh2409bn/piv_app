// lib/features/returns/data/models/return_request_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ReturnRequestModel extends Equatable {
  final String id;
  final String userId;
  final String userDisplayName;
  final String orderId;
  final List<Map<String, dynamic>> items;
  final List<String> imageUrls;
  final String userNotes;
  final String status;
  final String? adminNotes;
  final String? rejectionReason;
  final double penaltyFee; // <<< THÊM MỚI
  final Timestamp createdAt;

  const ReturnRequestModel({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    required this.orderId,
    required this.items,
    required this.imageUrls,
    required this.userNotes,
    required this.status,
    this.adminNotes,
    this.rejectionReason,
    this.penaltyFee = 0.0, // <<< THÊM MỚI
    required this.createdAt,
  });

  factory ReturnRequestModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // --- SỬA LỖI TỪ LẦN TRƯỚC VÀ CẬP NHẬT ---
    final itemsList = (data['items'] as List<dynamic>?)?.map((itemMap) {
      final map = itemMap as Map<String, dynamic>;
      return {
        'productId': map['productId'],
        'productName': map['productName'],
        'quantity': map['returnedQuantity'] ?? 0, // Đọc 'returnedQuantity'
        'itemUnit': map['itemUnit'] ?? 'sản phẩm', // Đọc 'itemUnit'
        'reason': map['reason'],
      };
    }).toList() ?? [];
    // --- KẾT THÚC SỬA LỖI ---

    return ReturnRequestModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userDisplayName: data['userDisplayName'] ?? 'Không rõ',
      orderId: data['orderId'] ?? '',
      items: itemsList, // Sử dụng danh sách đã được xử lý
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      userNotes: data['userNotes'] ?? '',
      status: data['status'] ?? 'unknown',
      adminNotes: data['adminNotes'],
      rejectionReason: data['rejectionReason'],
      penaltyFee: (data['penaltyFee'] as num? ?? 0).toDouble(), // <<< THÊM MỚI
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    orderId,
    status,
    createdAt,
    rejectionReason,
    penaltyFee // <<< THÊM MỚI
  ];
}