// lib/data/models/bulk_price_request_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class BulkPriceRequestModel extends Equatable {
  final String id;
  final String requesterId;
  final String requesterName;
  final String requesterRole; // 'accountant' | 'sales_rep'
  final String priceType; // 'general' | 'special_adjust' | 'special_from_general'
  final String adjustmentType; // 'percentage' | 'amount'
  final double adjustmentValue; // + = nâng, - = hạ
  final String productTarget; // 'all' | 'foliar_fertilizer' | 'root_fertilizer'
  final String agentTarget; // 'all' | 'agent_1' | 'agent_2' | 'sales_rep_group' | 'specific'
  final String? salesRepId; // nếu agentTarget = 'sales_rep_group'
  final String? salesRepName;
  final List<String> specificAgentIds; // nếu agentTarget = 'specific'
  final List<String> specificAgentNames;
  final List<String> excludedAgentIds;
  final List<String> excludedAgentNames;
  final String status; // 'pending' | 'approved' | 'rejected'
  final DateTime createdAt;
  final String? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final int? affectedCount; // Số sản phẩm/đại lý bị ảnh hưởng

  const BulkPriceRequestModel({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.requesterRole,
    required this.priceType,
    required this.adjustmentType,
    required this.adjustmentValue,
    required this.productTarget,
    required this.agentTarget,
    this.salesRepId,
    this.salesRepName,
    this.specificAgentIds = const [],
    this.specificAgentNames = const [],
    this.excludedAgentIds = const [],
    this.excludedAgentNames = const [],
    required this.status,
    required this.createdAt,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.rejectionReason,
    this.affectedCount,
  });

  @override
  List<Object?> get props => [
    id, requesterId, requesterName, requesterRole,
    priceType, adjustmentType, adjustmentValue,
    productTarget, agentTarget, salesRepId, salesRepName,
    specificAgentIds, specificAgentNames,
    excludedAgentIds, excludedAgentNames,
    status, createdAt, approvedBy, approvedByName, approvedAt,
    rejectionReason, affectedCount,
  ];

  String get displayPriceType {
    switch (priceType) {
      case 'general': return 'Giá chung';
      case 'special_adjust': return 'Giá riêng (điều chỉnh)';
      case 'special_from_general': return 'Giá riêng (từ giá chung)';
      default: return priceType;
    }
  }

  String get displayDirection => adjustmentValue > 0 ? 'Nâng' : 'Hạ';

  String get displayAdjustment {
    final absVal = adjustmentValue.abs();
    if (adjustmentType == 'percentage') {
      return '${absVal.toStringAsFixed(absVal.truncateToDouble() == absVal ? 0 : 1)}%';
    }
    return '${absVal.toInt()} VND';
  }

  String get displayProductTarget {
    switch (productTarget) {
      case 'all': return 'Tất cả sản phẩm';
      case 'foliar_fertilizer': return 'Phân bón lá';
      case 'root_fertilizer': return 'Phân bón gốc';
      default: return productTarget;
    }
  }

  String get displayAgentTarget {
    switch (agentTarget) {
      case 'all': return 'Tất cả đại lý';
      case 'agent_1': return 'Đại lý cấp 1';
      case 'agent_2': return 'Đại lý cấp 2';
      case 'sales_rep_group': return 'Nhóm NVKD: ${salesRepName ?? salesRepId}';
      case 'specific': return '${specificAgentNames.length} đại lý cụ thể';
      default: return agentTarget;
    }
  }

  factory BulkPriceRequestModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>? ?? {};
    return BulkPriceRequestModel(
      id: snap.id,
      requesterId: data['requesterId'] as String? ?? '',
      requesterName: data['requesterName'] as String? ?? '',
      requesterRole: data['requesterRole'] as String? ?? '',
      priceType: data['priceType'] as String? ?? 'general',
      adjustmentType: data['adjustmentType'] as String? ?? 'percentage',
      adjustmentValue: (data['adjustmentValue'] as num? ?? 0).toDouble(),
      productTarget: data['productTarget'] as String? ?? 'all',
      agentTarget: data['agentTarget'] as String? ?? 'all',
      salesRepId: data['salesRepId'] as String?,
      salesRepName: data['salesRepName'] as String?,
      specificAgentIds: List<String>.from(data['specificAgentIds'] ?? []),
      specificAgentNames: List<String>.from(data['specificAgentNames'] ?? []),
      excludedAgentIds: List<String>.from(data['excludedAgentIds'] ?? []),
      excludedAgentNames: List<String>.from(data['excludedAgentNames'] ?? []),
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      approvedBy: data['approvedBy'] as String?,
      approvedByName: data['approvedByName'] as String?,
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'] as String?,
      affectedCount: data['affectedCount'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterRole': requesterRole,
      'priceType': priceType,
      'adjustmentType': adjustmentType,
      'adjustmentValue': adjustmentValue,
      'productTarget': productTarget,
      'agentTarget': agentTarget,
      'salesRepId': salesRepId,
      'salesRepName': salesRepName,
      'specificAgentIds': specificAgentIds,
      'specificAgentNames': specificAgentNames,
      'excludedAgentIds': excludedAgentIds,
      'excludedAgentNames': excludedAgentNames,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectionReason': rejectionReason,
      'affectedCount': affectedCount,
    };
  }
}
