// lib/data/models/payment_info_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class PaymentInfoModel extends Equatable {
  final String bankName;
  final String accountHolder;
  final String accountNumber;
  final String branch;
  final String qrCodeImageUrl;

  const PaymentInfoModel({
    required this.bankName,
    required this.accountHolder,
    required this.accountNumber,
    required this.branch,
    required this.qrCodeImageUrl,
  });

  factory PaymentInfoModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    return PaymentInfoModel(
      bankName: data['bankName'] ?? '',
      accountHolder: data['accountHolder'] ?? '',
      accountNumber: data['accountNumber'] ?? '',
      branch: data['branch'] ?? '',
      qrCodeImageUrl: data['qrCodeImageUrl'] ?? '',
    );
  }

  @override
  List<Object?> get props => [bankName, accountHolder, accountNumber, branch, qrCodeImageUrl];
}