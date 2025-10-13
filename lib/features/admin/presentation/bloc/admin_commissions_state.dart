part of 'admin_commissions_cubit.dart';

enum AdminCommissionsStatus { initial, loading, success, error }

class AdminCommissionsState extends Equatable {
  final AdminCommissionsStatus status;
  final List<CommissionWithDetails> allCommissions;
  final List<CommissionWithDetails> filteredCommissions;
  final DateTime? startDate;
  final DateTime? endDate;
  final String currentFilter;
  final String? errorMessage;

  // <<< CÁC TRƯỜNG MỚI >>>
  final List<UserModel> salesReps; // Để hiển thị trong Dropdown
  final String? selectedSalesRepId; // ID của NVKD đang được chọn để lọc

  const AdminCommissionsState({
    this.status = AdminCommissionsStatus.initial,
    this.allCommissions = const [],
    this.filteredCommissions = const [],
    this.currentFilter = 'all',
    this.startDate,
    this.endDate,
    this.errorMessage,
    this.salesReps = const [],
    this.selectedSalesRepId,
  });

  @override
  List<Object?> get props => [
    status, allCommissions, filteredCommissions, currentFilter,
    startDate, endDate, errorMessage, salesReps, selectedSalesRepId
  ];

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
    List<UserModel>? salesReps,
    String? selectedSalesRepId,
    bool forceSalesRepToNull = false,
  }) {
    return AdminCommissionsState(
      status: status ?? this.status,
      allCommissions: allCommissions ?? this.allCommissions,
      filteredCommissions: filteredCommissions ?? this.filteredCommissions,
      currentFilter: currentFilter ?? this.currentFilter,
      errorMessage: errorMessage ?? this.errorMessage,
      startDate: forceStartDateToNull ? null : (startDate ?? this.startDate),
      endDate: forceEndDateToNull ? null : (endDate ?? this.endDate),
      salesReps: salesReps ?? this.salesReps,
      selectedSalesRepId: forceSalesRepToNull ? null : (selectedSalesRepId ?? this.selectedSalesRepId),
    );
  }
}