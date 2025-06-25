part of 'admin_commissions_cubit.dart';

enum AdminCommissionsStatus { initial, loading, success, error }

class AdminCommissionsState extends Equatable {
  final AdminCommissionsStatus status;
  final List<CommissionModel> allCommissions;
  final List<CommissionModel> filteredCommissions;
  final String currentFilter; // 'pending', 'paid', 'all'
  final String? errorMessage;

  const AdminCommissionsState({
    this.status = AdminCommissionsStatus.initial,
    this.allCommissions = const [],
    this.filteredCommissions = const [],
    this.currentFilter = 'pending', // Mặc định xem các khoản chờ thanh toán
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, allCommissions, filteredCommissions, currentFilter, errorMessage];

  AdminCommissionsState copyWith({
    AdminCommissionsStatus? status,
    List<CommissionModel>? allCommissions,
    List<CommissionModel>? filteredCommissions,
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