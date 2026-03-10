import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class DebtUpdateRequestModel extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final double oldDebtAmount;
  final double newDebtAmount;
  final String requestedBy;
  final String requestedByName;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reason;

  const DebtUpdateRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.oldDebtAmount,
    required this.newDebtAmount,
    required this.requestedBy,
    required this.requestedByName,
    required this.status,
    required this.createdAt,
    this.reviewedBy,
    this.reviewedAt,
    this.reason,
  });

  factory DebtUpdateRequestModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    return DebtUpdateRequestModel(
      id: snap.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      oldDebtAmount: (data['oldDebtAmount'] as num?)?.toDouble() ?? 0.0,
      newDebtAmount: (data['newDebtAmount'] as num?)?.toDouble() ?? 0.0,
      requestedBy: data['requestedBy'] ?? '',
      requestedByName: data['requestedByName'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      reviewedBy: data['reviewedBy'],
      reviewedAt: data['reviewedAt'] != null 
          ? (data['reviewedAt'] as Timestamp).toDate() 
          : null,
      reason: data['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'oldDebtAmount': oldDebtAmount,
      'newDebtAmount': newDebtAmount,
      'requestedBy': requestedBy,
      'requestedByName': requestedByName,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reason': reason,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        oldDebtAmount,
        newDebtAmount,
        requestedBy,
        requestedByName,
        status,
        createdAt,
        reviewedBy,
        reviewedAt,
        reason,
      ];
}
