import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class DebtTransactionModel extends Equatable {
  final String id;
  final double amount; // Số tiền thay đổi (có thể âm hoặc dương)
  final double previousDebt; // Công nợ trước khi thay đổi
  final double newDebt; // Công nợ sau khi thay đổi
  final String type; // 'manual_update', 'order_payment', 'direct_payment'
  final String updatedById; // ID của nhân viên thực hiện thay đổi
  final String? notes; // Ghi chú (nếu có)
  final String? orderId; // ID đơn hàng liên quan (nếu có)
  final Timestamp createdAt;

  const DebtTransactionModel({
    required this.id,
    required this.amount,
    required this.previousDebt,
    required this.newDebt,
    required this.type,
    required this.updatedById,
    this.notes,
    this.orderId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, amount, previousDebt, newDebt, type, updatedById, notes, orderId, createdAt];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'previousDebt': previousDebt,
      'newDebt': newDebt,
      'type': type,
      'updatedById': updatedById,
      'notes': notes,
      'orderId': orderId,
      'createdAt': createdAt,
    };
  }

  factory DebtTransactionModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    return DebtTransactionModel(
      id: snap.id,
      amount: (data['amount'] as num).toDouble(),
      previousDebt: (data['previousDebt'] as num).toDouble(),
      newDebt: (data['newDebt'] as num).toDouble(),
      type: data['type'] as String,
      updatedById: data['updatedById'] as String,
      notes: data['notes'] as String?,
      orderId: data['orderId'] as String?,
      createdAt: data['createdAt'] as Timestamp,
    );
  }
}