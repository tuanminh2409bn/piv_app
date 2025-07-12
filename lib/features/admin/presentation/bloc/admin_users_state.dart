part of 'admin_users_cubit.dart';

enum AdminUsersStatus { initial, loading, success, error }

// Dùng record để nhóm NVKD và số lượng đại lý của họ
typedef SalesRepWithAgentCount = (UserModel salesRep, int agentCount);

class AdminUsersState extends Equatable {
  const AdminUsersState({
    this.status = AdminUsersStatus.initial,
    this.salesReps = const [],
    this.unassignedAgents = const [],
    this.admins = const [],
    this.errorMessage,
  });

  final AdminUsersStatus status;
  final List<SalesRepWithAgentCount> salesReps;
  final List<UserModel> unassignedAgents;
  final List<UserModel> admins;
  final String? errorMessage;

  AdminUsersState copyWith({
    AdminUsersStatus? status,
    List<SalesRepWithAgentCount>? salesReps,
    List<UserModel>? unassignedAgents,
    List<UserModel>? admins,
    String? errorMessage,
  }) {
    return AdminUsersState(
      status: status ?? this.status,
      salesReps: salesReps ?? this.salesReps,
      unassignedAgents: unassignedAgents ?? this.unassignedAgents,
      admins: admins ?? this.admins,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, salesReps, unassignedAgents, admins, errorMessage];
}