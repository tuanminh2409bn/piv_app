import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class SpecialPriceModel extends Equatable {
  final String userId;
  final String productId;
  final double price;
  final Timestamp? updatedAt;
  final String? updatedBy;

  const SpecialPriceModel({
    required this.userId,
    required this.productId,
    required this.price,
    this.updatedAt,
    this.updatedBy,
  });

  @override
  List<Object?> get props => [userId, productId, price, updatedAt, updatedBy];

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productId': productId,
      'price': price,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
  }

  factory SpecialPriceModel.fromMap(Map<String, dynamic> map, String userId, String productId) {
    return SpecialPriceModel(
      userId: userId,
      productId: productId,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      updatedAt: map['updatedAt'] as Timestamp?,
      updatedBy: map['updatedBy'] as String?,
    );
  }

  factory SpecialPriceModel.fromSnapshot(DocumentSnapshot snap, String userId) {
    final data = snap.data() as Map<String, dynamic>? ?? {};
    return SpecialPriceModel(
      userId: userId,
      productId: snap.id,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      updatedAt: data['updatedAt'] as Timestamp?,
      updatedBy: data['updatedBy'] as String?,
    );
  }
}
