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
  final String? rejectionReason; // <<< THÊM MỚI
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
    this.rejectionReason, // <<< THÊM MỚI
    required this.createdAt,
  });

  factory ReturnRequestModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReturnRequestModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userDisplayName: data['userDisplayName'] ?? 'Không rõ',
      orderId: data['orderId'] ?? '',
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      userNotes: data['userNotes'] ?? '',
      status: data['status'] ?? 'unknown',
      adminNotes: data['adminNotes'],
      rejectionReason: data['rejectionReason'], // <<< THÊM MỚI
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  @override
  List<Object?> get props => [id, userId, orderId, status, createdAt, rejectionReason]; // <<< THÊM MỚI
}