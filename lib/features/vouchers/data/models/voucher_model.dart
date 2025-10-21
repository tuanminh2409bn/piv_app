// lib/features/vouchers/data/models/voucher_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// <<< GIỮ NGUYÊN ENUM CỦA BẠN, RẤT TỐT! >>>
enum DiscountType { percentage, fixedAmount }

// <<< THÊM MỚI: CÁC HẰNG SỐ TRẠNG THÁI CHO DỄ QUẢN LÝ >>>
class VoucherStatus {
  static const String pendingApproval = 'pending_approval';
  static const String active = 'active';
  static const String rejected = 'rejected';
  static const String pendingDeletion = 'pending_deletion';
  static const String inactive = 'inactive';
}

// <<< THÊM MỚI: MODEL ĐỂ LƯU LỊCH SỬ THAY ĐỔI >>>
class VoucherHistoryEntry extends Equatable {
  final String action;
  final String actorId;
  final Timestamp timestamp;
  final String? notes;

  const VoucherHistoryEntry({
    required this.action,
    required this.actorId,
    required this.timestamp,
    this.notes,
  });

  @override
  List<Object?> get props => [action, actorId, timestamp, notes];

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'actorId': actorId,
      'timestamp': timestamp,
      'notes': notes,
    };
  }

  factory VoucherHistoryEntry.fromMap(Map<String, dynamic> map) {
    return VoucherHistoryEntry(
      action: map['action'] as String,
      actorId: map['actorId'] as String,
      timestamp: map['timestamp'] as Timestamp,
      notes: map['notes'] as String?,
    );
  }
}


class VoucherModel extends Equatable {
  final String id;
  final String description;
  final DiscountType discountType;
  final double discountValue;
  final double? maxDiscountAmount; // <<< THÊM MỚI: Mức giảm tối đa cho %
  final double minOrderValue;   // <<< THÊM MỚI: Giá trị đơn hàng tối thiểu
  final int maxUses; // Số lần sử dụng tối đa
  final int usedCount;
  final Timestamp createdAt;
  final Timestamp expiresAt;
  final String status;
  final String createdBy; // User ID của NVKD
  final String? approvedBy; // User ID của Admin
  final List<VoucherHistoryEntry> history;
  final String? statusBeforeDeletion; // Lưu trạng thái trước khi yêu cầu xóa


  const VoucherModel({
    required this.id,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.maxDiscountAmount,
    required this.minOrderValue,
    required this.maxUses,
    this.usedCount = 0,
    required this.createdAt,
    required this.expiresAt,
    this.status = VoucherStatus.pendingApproval,
    required this.createdBy,
    this.approvedBy,
    this.history = const [],
    this.statusBeforeDeletion,
  });

  String get discountTypeString =>
      discountType == DiscountType.percentage ? 'percentage' : 'fixed_amount';

  static DiscountType _discountTypeFromString(String type) {
    return type == 'percentage' ? DiscountType.percentage : DiscountType.fixedAmount;
  }

  // <<< CẬP NHẬT HÀM TÍNH TOÁN ĐỂ KIỂM TRA STATUS VÀ CÁC ĐIỀU KIỆN MỚI >>>
  double calculateDiscount(double subtotal) {
    if (status != VoucherStatus.active ||
        DateTime.now().isAfter(expiresAt.toDate()) ||
        (maxUses != 0 && usedCount >= maxUses) ||
        subtotal < minOrderValue) {
      return 0.0;
    }

    if (discountType == DiscountType.percentage) {
      final discount = (subtotal * discountValue / 100);
      // Nếu có mức giảm tối đa, hãy áp dụng nó
      if (maxDiscountAmount != null && discount > maxDiscountAmount!) {
        return maxDiscountAmount!;
      }
      return discount.roundToDouble();
    } else {
      return discountValue > subtotal ? subtotal : discountValue;
    }
  }

  @override
  List<Object?> get props => [
    id, description, discountType, discountValue, maxDiscountAmount,
    minOrderValue, maxUses, usedCount, createdAt, expiresAt,
    status, createdBy, approvedBy, history, statusBeforeDeletion
  ];

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'discountType': discountTypeString,
      'discountValue': discountValue,
      'maxDiscountAmount': maxDiscountAmount,
      'minOrderValue': minOrderValue,
      'maxUses': maxUses,
      'usedCount': usedCount,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'status': status,
      'createdBy': createdBy,
      'approvedBy': approvedBy,
      'history': history.map((e) => e.toMap()).toList(),
      'statusBeforeDeletion': statusBeforeDeletion,
    };
  }

  factory VoucherModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    return VoucherModel(
      id: snap.id,
      description: data['description'] ?? '',
      discountType: _discountTypeFromString(data['discountType'] ?? 'fixed_amount'),
      discountValue: (data['discountValue'] as num?)?.toDouble() ?? 0.0,
      maxDiscountAmount: (data['maxDiscountAmount'] as num?)?.toDouble(),
      minOrderValue: (data['minOrderValue'] as num?)?.toDouble() ?? 0.0,
      maxUses: data['maxUses'] ?? 0,
      usedCount: data['usedCount'] ?? 0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      expiresAt: data['expiresAt'] ?? Timestamp.now(),
      // --- Các trường mới
      status: data['status'] ?? VoucherStatus.inactive,
      createdBy: data['createdBy'] ?? '',
      approvedBy: data['approvedBy'],
      history: (data['history'] as List<dynamic>?)
          ?.map((e) => VoucherHistoryEntry.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      statusBeforeDeletion: data['statusBeforeDeletion'],
    );
  }

  VoucherModel copyWith({
    String? id,
    String? description,
    DiscountType? discountType,
    double? discountValue,
    bool setMaxDiscountAmountNull = false,
    double? maxDiscountAmount,
    double? minOrderValue,
    int? maxUses,
    int? usedCount,
    Timestamp? createdAt,
    Timestamp? expiresAt,
    String? status,
    String? createdBy,
    bool setApprovedByNull = false,
    String? approvedBy,
    List<VoucherHistoryEntry>? history,
    bool setStatusBeforeDeletionNull = false,
    String? statusBeforeDeletion,
  }) {
    return VoucherModel(
      id: id ?? this.id,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      maxDiscountAmount: setMaxDiscountAmountNull ? null : (maxDiscountAmount ?? this.maxDiscountAmount),
      minOrderValue: minOrderValue ?? this.minOrderValue,
      maxUses: maxUses ?? this.maxUses,
      usedCount: usedCount ?? this.usedCount,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      approvedBy: setApprovedByNull ? null : (approvedBy ?? this.approvedBy),
      history: history ?? this.history,
      statusBeforeDeletion: setStatusBeforeDeletionNull ? null : (statusBeforeDeletion ?? this.statusBeforeDeletion),
    );
  }
}