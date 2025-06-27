import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum DiscountType { percentage, fixedAmount }

class VoucherModel extends Equatable {
  final String id; // Chính là mã code, ví dụ: PIV2025
  final String description; // Mô tả ngắn, ví dụ: "Giảm giá mừng năm mới"
  final DiscountType discountType; // Loại giảm giá: theo % hay số tiền cố định
  final double discountValue; // Giá trị giảm (ví dụ: 10 cho 10% hoặc 50000 cho 50,000đ)
  final String salesRepId; // ID của NVKD sở hữu voucher này
  final Timestamp createdAt;
  final Timestamp expiresAt; // Ngày hết hạn
  final int maxUses; // Số lần sử dụng tối đa (0 là không giới hạn)
  final int usesCount; // Số lần đã sử dụng
  final bool isActive; // Để bật/tắt voucher

  const VoucherModel({
    required this.id,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.salesRepId,
    required this.createdAt,
    required this.expiresAt,
    this.maxUses = 1,
    this.usesCount = 0,
    this.isActive = true,
  });

  // Helper để chuyển đổi qua lại giữa Enum và String để lưu trên Firestore
  String get discountTypeString =>
      discountType == DiscountType.percentage ? 'percentage' : 'fixed_amount';

  static DiscountType _discountTypeFromString(String type) {
    return type == 'percentage' ? DiscountType.percentage : DiscountType.fixedAmount;
  }

  // Phương thức tính toán số tiền được giảm
  double calculateDiscount(double subtotal) {
    if (!isActive || DateTime.now().isAfter(expiresAt.toDate())) {
      return 0.0;
    }
    if (maxUses != 0 && usesCount >= maxUses) {
      return 0.0;
    }

    if (discountType == DiscountType.percentage) {
      return (subtotal * discountValue / 100).roundToDouble();
    } else {
      // Đảm bảo không giảm giá nhiều hơn giá trị đơn hàng
      return discountValue > subtotal ? subtotal : discountValue;
    }
  }

  @override
  List<Object?> get props => [
    id,
    description,
    discountType,
    discountValue,
    salesRepId,
    createdAt,
    expiresAt,
    maxUses,
    usesCount,
    isActive
  ];

  // Chuyển đổi từ Object thành Map để lưu lên Firestore
  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'discountType': discountTypeString,
      'discountValue': discountValue,
      'salesRepId': salesRepId,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'maxUses': maxUses,
      'usesCount': usesCount,
      'isActive': isActive,
    };
  }

  // Tạo Object từ một DocumentSnapshot của Firestore
  factory VoucherModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    return VoucherModel(
      id: snap.id,
      description: data['description'] ?? '',
      discountType: _discountTypeFromString(data['discountType'] ?? 'fixed_amount'),
      discountValue: (data['discountValue'] as num?)?.toDouble() ?? 0.0,
      salesRepId: data['salesRepId'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      expiresAt: data['expiresAt'] ?? Timestamp.now(),
      maxUses: data['maxUses'] ?? 0,
      usesCount: data['usesCount'] ?? 0,
      isActive: data['isActive'] ?? false,
    );
  }
}

