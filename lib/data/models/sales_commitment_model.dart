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

// Model cho yêu cầu hủy
class CancellationRequestModel extends Equatable {
  final String requesterId;
  final String requesterName;
  final String requesterRole;
  final String reason;
  final DateTime requestedAt;

  const CancellationRequestModel({
    required this.requesterId,
    required this.requesterName,
    required this.requesterRole,
    required this.reason,
    required this.requestedAt,
  });

  @override
  List<Object?> get props => [requesterId, requesterName, requesterRole, reason, requestedAt];

  factory CancellationRequestModel.fromMap(Map<String, dynamic> map) {
    return CancellationRequestModel(
      requesterId: map['requesterId'] as String? ?? '',
      requesterName: map['requesterName'] as String? ?? '',
      requesterRole: map['requesterRole'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      requestedAt: (map['requestedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
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
  final String status; // 'active', 'completed', 'expired', 'pending_cancellation', 'cancelled'
  final CommitmentDetailsModel? commitmentDetails;
  final CancellationRequestModel? cancellationRequest;
  final String? cancellationReason;
  final String? cancelledBy;
  final String? cancelledByName; // <--- THÊM MỚI
  final DateTime? cancelledAt;
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
    this.cancellationRequest,
    this.cancellationReason,
    this.cancelledBy,
    this.cancelledByName, // <--- THÊM MỚI
    this.cancelledAt,
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
    cancellationRequest,
    cancellationReason,
    cancelledBy,
    cancelledByName,
    cancelledAt,
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
      cancellationRequest: data['cancellationRequest'] != null
          ? CancellationRequestModel.fromMap(data['cancellationRequest'])
          : null,
      cancellationReason: data['cancellationReason'] as String?,
      cancelledBy: data['cancelledBy'] as String?,
      cancelledByName: data['cancelledByName'] as String?, // <--- THÊM MỚI
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }
}
