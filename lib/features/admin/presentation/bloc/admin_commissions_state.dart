part of 'admin_commissions_cubit.dart';

enum AdminCommissionsStatus { initial, loading, success, error }

class AdminCommissionsState extends Equatable {
  final AdminCommissionsStatus status;
  // --- SỬA LẠI: Dùng model mới ---
  final List<CommissionWithDetails> allCommissions;
  final List<CommissionWithDetails> filteredCommissions;
  // -----------------------------
  final String currentFilter;
  final String? errorMessage;

  const AdminCommissionsState({
    this.status = AdminCommissionsStatus.initial,
    this.allCommissions = const [],
    this.filteredCommissions = const [],
    this.currentFilter = 'pending',
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
  }) {
    return AdminCommissionsState(
      status: status ?? this.status,
      allCommissions: allCommissions ?? this.allCommissions,
      filteredCommissions: filteredCommissions ?? this.filteredCommissions,
      currentFilter: currentFilter ?? this.currentFilter,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}