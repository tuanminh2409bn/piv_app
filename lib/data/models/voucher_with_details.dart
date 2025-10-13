import 'package:equatable/equatable.dart';
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';

class VoucherWithDetails extends Equatable {
  final VoucherModel voucher;
  final String createdByName;

  const VoucherWithDetails({
    required this.voucher,
    required this.createdByName,
  });

  @override
  List<Object> get props => [voucher, createdByName];
}