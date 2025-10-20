// lib/features/returns/domain/entities/return_request_item.dart

import 'package:equatable/equatable.dart';

class ReturnRequestItem extends Equatable {
  final String productId;
  final String productName;
  final int returnedQuantity;
  final String itemUnit;
  final String reason;

  const ReturnRequestItem({
    required this.productId,
    required this.productName,
    required this.returnedQuantity,
    required this.itemUnit,
    required this.reason,
  });

  @override
  List<Object?> get props => [productId, productName, returnedQuantity, itemUnit, reason];

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'returnedQuantity': returnedQuantity,
      'itemUnit': itemUnit,
      'reason': reason,
    };
  }
}