import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/commission_model.dart';

class CommissionWithDetails extends Equatable {
  final CommissionModel commission;
  final String salesRepName;

  const CommissionWithDetails({
    required this.commission,
    required this.salesRepName,
  });

  @override
  List<Object?> get props => [commission, salesRepName];
}