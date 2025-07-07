import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/commission_model.dart';

class CommissionWithDetails extends Equatable {
  final CommissionModel commission;
  final String salesRepName;
  final String agentName; // <<< THÊM TRƯỜNG MỚI

  const CommissionWithDetails({
    required this.commission,
    required this.salesRepName,
    required this.agentName, // <<< THÊM VÀO CONSTRUCTOR
  });

  @override
  List<Object> get props => [commission, salesRepName, agentName]; // <<< THÊM VÀO PROPS
}