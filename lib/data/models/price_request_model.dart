import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class PriceChangeItem extends Equatable {
  final String productId;
  final String productName;
  final String productImageUrl;
  final double generalPrice; // Giá niêm yết (Cấp 1/Cấp 2)
  final double oldPrice; // Giá riêng cũ (nếu có)
  final double newPrice; // Giá riêng mới đề xuất

  const PriceChangeItem({
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.generalPrice,
    required this.oldPrice,
    required this.newPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'generalPrice': generalPrice,
      'oldPrice': oldPrice,
      'newPrice': newPrice,
    };
  }

  factory PriceChangeItem.fromMap(Map<String, dynamic> map) {
    return PriceChangeItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImageUrl: map['productImageUrl'] ?? '',
      generalPrice: (map['generalPrice'] as num?)?.toDouble() ?? 0.0,
      oldPrice: (map['oldPrice'] as num?)?.toDouble() ?? 0.0,
      newPrice: (map['newPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [productId, newPrice, generalPrice, oldPrice];
}

class PriceRequestModel extends Equatable {
  final String id;
  final String agentId;
  final String agentName;
  final String requesterId;
  final String requesterName;
  final String requesterRole; // 'accountant' or 'sales_rep'
  final String type; // 'update_price_batch', 'toggle_mode'
  final List<PriceChangeItem> items; // Danh sách các sản phẩm thay đổi giá
  final bool? newGeneralPriceState; // Cho toggle_mode
  final String status; // 'pending', 'approved', 'rejected'
  final Timestamp createdAt;
  final String? rejectionReason;
  final String? approvedBy;
  final Timestamp? approvedAt;

  const PriceRequestModel({
    required this.id,
    required this.agentId,
    required this.agentName,
    required this.requesterId,
    required this.requesterName,
    required this.requesterRole,
    required this.type,
    this.items = const [],
    this.newGeneralPriceState,
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
      'type': type,
      'items': items.map((x) => x.toMap()).toList(),
      'newGeneralPriceState': newGeneralPriceState,
      'status': status,
      'createdAt': createdAt,
      'rejectionReason': rejectionReason,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt,
    };
  }

  factory PriceRequestModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    return PriceRequestModel(
      id: snap.id,
      agentId: data['agentId'] ?? '',
      agentName: data['agentName'] ?? 'Unknown Agent',
      requesterId: data['requesterId'] ?? '',
      requesterName: data['requesterName'] ?? 'Unknown',
      requesterRole: data['requesterRole'] ?? '',
      type: data['type'] ?? 'update_price_batch',
      items: List<PriceChangeItem>.from(
        (data['items'] as List<dynamic>? ?? []).map<PriceChangeItem>(
          (x) => PriceChangeItem.fromMap(x as Map<String, dynamic>),
        ),
      ),
      newGeneralPriceState: data['newGeneralPriceState'],
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      rejectionReason: data['rejectionReason'],
      approvedBy: data['approvedBy'],
      approvedAt: data['approvedAt'],
    );
  }

  @override
  List<Object?> get props => [id, agentId, status, type, items];
}