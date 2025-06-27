part of 'admin_commissions_cubit.dart';

enum AdminCommissionsStatus { initial, loading, success, error }

class AdminCommissionsState extends Equatable {
  final AdminCommissionsStatus status;
  final List<CommissionWithDetails> allCommissions;
  final List<CommissionWithDetails> filteredCommissions;
  final DateTime? startDate;
  final DateTime? endDate;
  // -----------------------------
  final String currentFilter;
  final String? errorMessage;

  const AdminCommissionsState({
    this.status = AdminCommissionsStatus.initial,
    this.allCommissions = const [],
    this.filteredCommissions = const [],
    this.currentFilter = 'all',
    this.startDate,
    this.endDate,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, allCommissions, filteredCommissions, currentFilter, errorMessage];

  AdminCommissionsState copyWith({
    AdminCommissionsStatus? status,
    List<CommissionWithDetails>? allCommissions,
    List<CommissionWithDetails>? filteredCommissions,
    String? currentFilter,
    String? errorMessage,
    DateTime? startDate,
    bool forceStartDateToNull = false,
    DateTime? endDate,
    bool forceEndDateToNull = false,
  }) {
    return AdminCommissionsState(
      status: status ?? this.status,
      allCommissions: allCommissions ?? this.allCommissions,
      filteredCommissions: filteredCommissions ?? this.filteredCommissions,
      currentFilter: currentFilter ?? this.currentFilter,
      errorMessage: errorMessage ?? this.errorMessage,
      startDate: forceStartDateToNull ? null : (startDate ?? this.startDate),
      endDate: forceEndDateToNull ? null : (endDate ?? this.endDate),
    );
  }
}