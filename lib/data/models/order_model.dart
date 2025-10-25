// lib/data/models/order_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/address_model.dart';
import 'package:piv_app/data/models/order_item_model.dart';

class ReturnInfo extends Equatable {
  final String returnRequestId;
  final String returnStatus;

  const ReturnInfo({required this.returnRequestId, required this.returnStatus});

  @override
  List<Object?> get props => [returnRequestId, returnStatus];

  factory ReturnInfo.fromMap(Map<String, dynamic> map) {
    return ReturnInfo(
      returnRequestId: map['returnRequestId'] ?? '',
      returnStatus: map['returnStatus'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toMap() => {
    'returnRequestId': returnRequestId,
    'returnStatus': returnStatus,
  };
}

class PlacedByInfo extends Equatable {
  final String userId;
  final String role;

  const PlacedByInfo({required this.userId, required this.role});

  Map<String, dynamic> toMap() => {'userId': userId, 'role': role};

  factory PlacedByInfo.fromMap(Map<String, dynamic> map) {
    return PlacedByInfo(
      userId: map['userId'] ?? '',
      role: map['role'] ?? '',
    );
  }

  PlacedByInfo copyWith({String? userId, String? role}) {
    return PlacedByInfo(
      userId: userId ?? this.userId,
      role: role ?? this.role,
    );
  }

  @override
  List<Object?> get props => [userId, role];
}

class OrderModel extends Equatable {
  final String? id;
  final String userId;
  final List<OrderItemModel> items;
  final AddressModel shippingAddress;
  final double subtotal;
  final double shippingFee;
  final double discount;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final Timestamp? createdAt;
  final String? salesRepId;
  final double commissionDiscount;
  final double finalTotal;
  final PlacedByInfo? placedBy;
  final Timestamp? approvedAt;
  final Timestamp? rejectedAt;
  final String? rejectionReason;
  final Timestamp? shippingDate;
  final ReturnInfo? returnInfo;
  final double debtAmount;
  final double paidAmount;
  final double remainingDebt;
  final String? appliedVoucherCode;


  const OrderModel({
    this.id,
    required this.userId,
    required this.items,
    required this.shippingAddress,
    required this.subtotal,
    required this.shippingFee,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    this.paymentStatus = 'unpaid',
    required this.status,
    this.createdAt,
    this.salesRepId,
    this.commissionDiscount = 0.0,
    this.finalTotal = 0.0,
    this.placedBy,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.shippingDate,
    this.returnInfo,
    this.debtAmount = 0.0,
    this.paidAmount = 0.0,
    this.remainingDebt = 0.0,
    this.appliedVoucherCode,
  });

  OrderModel copyWith({
    String? id,
    String? userId,
    List<OrderItemModel>? items,
    AddressModel? shippingAddress,
    double? subtotal,
    double? shippingFee,
    double? discount,
    double? total,
    String? paymentMethod,
    String? paymentStatus,
    String? status,
    Timestamp? createdAt,
    String? salesRepId,
    double? commissionDiscount,
    double? finalTotal,
    PlacedByInfo? placedBy,
    Timestamp? approvedAt,
    Timestamp? rejectedAt,
    String? rejectionReason,
    ReturnInfo? returnInfo,
    double? debtAmount,
    double? paidAmount,
    double? remainingDebt,
    String? appliedVoucherCode,
    bool forceAppliedVoucherCodeToNull = false,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      subtotal: subtotal ?? this.subtotal,
      shippingFee: shippingFee ?? this.shippingFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      salesRepId: salesRepId ?? this.salesRepId,
      commissionDiscount: commissionDiscount ?? this.commissionDiscount,
      finalTotal: finalTotal ?? this.finalTotal,
      placedBy: placedBy ?? this.placedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      returnInfo: returnInfo ?? this.returnInfo,
      debtAmount: debtAmount ?? this.debtAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingDebt: remainingDebt ?? this.remainingDebt,
      appliedVoucherCode: forceAppliedVoucherCodeToNull ? null : (appliedVoucherCode ?? this.appliedVoucherCode),
    );
  }

  @override
  List<Object?> get props => [
    id, userId, items, shippingAddress, subtotal, shippingFee, discount, total,
    paymentMethod, paymentStatus, status, createdAt, salesRepId, commissionDiscount, finalTotal,
    placedBy, approvedAt, rejectedAt, rejectionReason, shippingDate, returnInfo, debtAmount, paidAmount, remainingDebt, appliedVoucherCode
  ];

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'shippingAddress': shippingAddress.toMap(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'status': status,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'salesRepId': salesRepId,
      'commissionDiscount': commissionDiscount,
      'finalTotal': finalTotal,
      'placedBy': placedBy?.toMap(),
      'approvedAt': approvedAt,
      'rejectedAt': rejectedAt,
      'rejectionReason': rejectionReason,
      'shippingDate': shippingDate,
      'returnInfo': returnInfo?.toMap(),
      'debtAmount': debtAmount,
      'paidAmount': paidAmount,
      'remainingDebt': remainingDebt,
      'appliedVoucherCode': appliedVoucherCode,
    };
  }

  factory OrderModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;

    return OrderModel(
      id: snap.id,
      userId: data['userId'] ?? '',
      items: (data['items'] as List<dynamic>)
          .map((itemData) =>
          OrderItemModel.fromMap(itemData as Map<String, dynamic>))
          .toList(),
      shippingAddress:
      AddressModel.fromMap(data['shippingAddress'] as Map<String, dynamic>),
      subtotal: (data['subtotal'] as num).toDouble(),
      shippingFee: (data['shippingFee'] as num).toDouble(),
      discount: (data['discount'] as num).toDouble(),
      total: (data['total'] as num).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'COD',
      paymentStatus: data['paymentStatus'] ?? 'unpaid',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] as Timestamp?,
      salesRepId: data['salesRepId'] as String?,
      commissionDiscount: (data['commissionDiscount'] as num?)?.toDouble() ?? 0.0,
      finalTotal: (data['finalTotal'] as num?)?.toDouble() ?? 0.0,
      placedBy: data['placedBy'] != null
          ? PlacedByInfo.fromMap(data['placedBy'] as Map<String, dynamic>)
          : null,
      approvedAt: data['approvedAt'] as Timestamp?,
      rejectedAt: data['rejectedAt'] as Timestamp?,
      rejectionReason: data['rejectionReason'] as String?,
      shippingDate: data['shippingDate'] as Timestamp?,
      returnInfo: data['returnInfo'] != null
          ? ReturnInfo.fromMap(data['returnInfo'] as Map<String, dynamic>)
          : null,
      debtAmount: (data['debtAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (data['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingDebt: (data['remainingDebt'] as num?)?.toDouble() ?? 0.0,
      appliedVoucherCode: data['appliedVoucherCode'] as String?,
    );
  }
}