import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class DiscountRequestModel extends Equatable {
  final String id;
  final String agentId;
  final String agentName;
  final String requesterId;
  final String requesterName;
  final String requesterRole; // 'accountant' or 'sales_rep'
  final Map<String, dynamic> customDiscount; // Chứa cấu hình chiết khấu đề xuất
  final String status; // 'pending', 'approved', 'rejected'
  final Timestamp createdAt;
  final String? rejectionReason;
  final String? approvedBy;
  final Timestamp? approvedAt;

  const DiscountRequestModel({
    required this.id,
    required this.agentId,
    required this.agentName,
    required this.requesterId,
    required this.requesterName,
    required this.requesterRole,
    required this.customDiscount,
    required this.status,
    required this.createdAt,
    this.rejectionReason,
    this.approvedBy,
    this.approvedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'agentId': agentId,
      'agentName': agentName,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterRole': requesterRole,
      'customDiscount': customDiscount,
      'status': status,
      'createdAt': createdAt,
      'rejectionReason': rejectionReason,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt,
    };
  }

  factory DiscountRequestModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    return DiscountRequestModel(
      id: snap.id,
      agentId: data['agentId'] ?? '',
      agentName: data['agentName'] ?? 'Unknown Agent',
      requesterId: data['requesterId'] ?? '',
      requesterName: data['requesterName'] ?? 'Unknown',
      requesterRole: data['requesterRole'] ?? '',
      customDiscount: Map<String, dynamic>.from(data['customDiscount'] ?? {}),
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      rejectionReason: data['rejectionReason'],
      approvedBy: data['approvedBy'],
      approvedAt: data['approvedAt'],
    );
  }

  @override
  List<Object?> get props => [id, agentId, status, createdAt];
}
