// lib/features/admin/data/models/quick_order_item_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class QuickOrderItemModel extends Equatable {
  final String id;
  final String productId;
  final DateTime addedAt;
  final String addedBy;

  const QuickOrderItemModel({
    required this.id,
    required this.productId,
    required this.addedAt,
    required this.addedBy,
  });

  @override
  List<Object> get props => [id, productId, addedAt, addedBy];

  factory QuickOrderItemModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    return QuickOrderItemModel(
      id: snap.id,
      productId: data['productId'] as String,
      addedAt: (data['addedAt'] as Timestamp).toDate(),
      addedBy: data['addedBy'] as String,
    );
  }
}