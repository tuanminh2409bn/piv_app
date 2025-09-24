import 'package:equatable/equatable.dart';

class ReturnRequestItem extends Equatable {
  final String productId;
  final String productName;
  final int quantity;
  final String reason;

  const ReturnRequestItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.reason,
  });

  @override
  List<Object?> get props => [productId, productName, quantity, reason];

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'reason': reason,
    };
  }
}