part of 'sales_rep_commissions_cubit.dart';

enum SalesRepCommissionsStatus { initial, loading, success, error }

class SalesRepCommissionsState extends Equatable {
  final SalesRepCommissionsStatus status;
  final List<CommissionModel> commissions;
  // --- THÊM CÁC TRƯỜNG MỚI ---
  final DateTime? startDate;
  final DateTime? endDate;
  // -------------------------
  final String? errorMessage;

  const SalesRepCommissionsState({
    this.status = SalesRepCommissionsStatus.initial,
    this.commissions = const [],
    this.startDate,
    this.endDate,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, commissions, startDate, endDate, errorMessage];

  SalesRepCommissionsState copyWith({
    SalesRepCommissionsStatus? status,
    List<CommissionModel>? commissions,
    DateTime? startDate,
    bool forceStartDateToNull = false,
    DateTime? endDate,
    bool forceEndDateToNull = false,
    String? errorMessage,
  }) {
    return SalesRepCommissionsState(
      status: status ?? this.status,
      commissions: commissions ?? this.commissions,
      startDate: forceStartDateToNull ? null : (startDate ?? this.startDate),
      endDate: forceEndDateToNull ? null : (endDate ?? this.endDate),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}