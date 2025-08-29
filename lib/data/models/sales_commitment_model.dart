// lib/data/models/sales_commitment_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// Model con để lưu chi tiết lời hứa từ công ty
class CommitmentDetailsModel extends Equatable {
  final String text;
  final String setByUserId;
  final String setByUserName;
  final DateTime createdAt;

  const CommitmentDetailsModel({
    required this.text,
    required this.setByUserId,
    required this.setByUserName,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [text, setByUserId, setByUserName, createdAt];

  factory CommitmentDetailsModel.fromMap(Map<String, dynamic> map) {
    return CommitmentDetailsModel(
      text: map['text'] as String? ?? '',
      setByUserId: map['setByUserId'] as String? ?? '',
      setByUserName: map['setByUserName'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }
}

// Model chính cho một cam kết
class SalesCommitmentModel extends Equatable {
  final String id;
  final String userId;
  final String userDisplayName;
  final String userRole;
  final double targetAmount;
  final double currentAmount;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'active', 'completed', 'expired'
  final CommitmentDetailsModel? commitmentDetails;
  final DateTime createdAt;

  const SalesCommitmentModel({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    required this.userRole,
    required this.targetAmount,
    required this.currentAmount,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.commitmentDetails,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    userDisplayName,
    userRole,
    targetAmount,
    currentAmount,
    startDate,
    endDate,
    status,
    commitmentDetails,
    createdAt,
  ];

  factory SalesCommitmentModel.fromSnap(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>? ?? {};
    return SalesCommitmentModel(
      id: snap.id,
      userId: data['userId'] as String? ?? '',
      userDisplayName: data['userDisplayName'] as String? ?? '',
      userRole: data['userRole'] as String? ?? '',
      targetAmount: (data['targetAmount'] as num? ?? 0).toDouble(),
      currentAmount: (data['currentAmount'] as num? ?? 0).toDouble(),
      startDate: (data['startDate'] as Timestamp? ?? Timestamp.now()).toDate(),
      endDate: (data['endDate'] as Timestamp? ?? Timestamp.now()).toDate(),
      status: data['status'] as String? ?? 'expired',
      commitmentDetails: data['commitmentDetails'] != null
          ? CommitmentDetailsModel.fromMap(data['commitmentDetails'])
          : null,
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }
}