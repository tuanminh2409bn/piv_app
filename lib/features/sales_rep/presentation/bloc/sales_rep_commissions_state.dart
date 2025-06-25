part of 'sales_rep_commissions_cubit.dart';

enum SalesRepCommissionsStatus { initial, loading, success, error }

class SalesRepCommissionsState extends Equatable {
  final SalesRepCommissionsStatus status;
  final List<CommissionModel> commissions;
  final String? errorMessage;

  const SalesRepCommissionsState({
    this.status = SalesRepCommissionsStatus.initial,
    this.commissions = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, commissions, errorMessage];

  SalesRepCommissionsState copyWith({
    SalesRepCommissionsStatus? status,
    List<CommissionModel>? commissions,
    String? errorMessage,
  }) {
    return SalesRepCommissionsState(
      status: status ?? this.status,
      commissions: commissions ?? this.commissions,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}