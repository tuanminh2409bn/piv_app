import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum CommissionStatus { pending, paid }

class CommissionModel extends Equatable {
  final String id;
  final String orderId;
  final double orderTotal;
  final double commissionRate; // Tỷ lệ hoa hồng tại thời điểm tạo
  final double commissionAmount; // Số tiền hoa hồng
  final String salesRepId;
  final String agentId;
  final String agentName;
  final CommissionStatus status;
  final Timestamp createdAt;
  final Timestamp? paidAt; // Thời điểm thanh toán
  final String? accountantId; // ID của kế toán đã duyệt chi

  const CommissionModel({
    required this.id,
    required this.orderId,
    required this.orderTotal,
    required this.commissionRate,
    required this.commissionAmount,
    required this.salesRepId,
    required this.agentId,
    required this.agentName,
    this.status = CommissionStatus.pending,
    required this.createdAt,
    this.paidAt,
    this.accountantId,
  });

  @override
  List<Object?> get props => [id, orderId, orderTotal, commissionRate, commissionAmount, salesRepId, agentId, agentName, status, createdAt, paidAt, accountantId];

  // Chuyển từ Enum sang String để lưu vào Firestore
  String get statusString => status == CommissionStatus.pending ? 'pending' : 'paid';

  // Chuyển từ String (đọc từ Firestore) sang Enum
  static CommissionStatus _statusFromString(String? statusStr) {
    return statusStr == 'paid' ? CommissionStatus.paid : CommissionStatus.pending;
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'orderTotal': orderTotal,
      'commissionRate': commissionRate,
      'commissionAmount': commissionAmount,
      'salesRepId': salesRepId,
      'agentId': agentId,
      'agentName': agentName,
      'status': statusString,
      'createdAt': createdAt,
      'paidAt': paidAt,
      'accountantId': accountantId,
    };
  }

  factory CommissionModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    return CommissionModel(
      id: snap.id,
      orderId: data['orderId'] as String,
      orderTotal: (data['orderTotal'] as num).toDouble(),
      commissionRate: (data['commissionRate'] as num).toDouble(),
      commissionAmount: (data['commissionAmount'] as num).toDouble(),
      salesRepId: data['salesRepId'] as String,
      agentId: data['agentId'] as String,
      agentName: data['agentName'] as String,
      status: _statusFromString(data['status'] as String?),
      createdAt: data['createdAt'] as Timestamp,
      paidAt: data['paidAt'] as Timestamp?,
      accountantId: data['accountantId'] as String?,
    );
  }
}