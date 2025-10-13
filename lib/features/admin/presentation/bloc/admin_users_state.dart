//lib/features/admin/presentation/bloc/admin_users_state.dart

part of 'admin_users_cubit.dart';

enum AdminUsersStatus { initial, loading, success, error, updating }

typedef SalesRepWithAgentCount = (UserModel salesRep, int agentCount);

class AdminUsersState extends Equatable {
  const AdminUsersState({
    this.status = AdminUsersStatus.initial,
    this.allUsers = const [],
    this.errorMessage,
  });

  final AdminUsersStatus status;
  final List<UserModel> allUsers;
  final String? errorMessage;

  List<SalesRepWithAgentCount> get salesRepsWithAgentCount {
    final reps = allUsers.where((user) => user.isSalesRep).toList();
    final agents = allUsers.where((user) => !user.isAdmin && !user.isSalesRep).toList();
    final agentCounts = <String, int>{};
    for (final agent in agents) {
      if (agent.salesRepId != null && agent.salesRepId!.isNotEmpty) {
        agentCounts[agent.salesRepId!] = (agentCounts[agent.salesRepId] ?? 0) + 1;
      }
    }
    return reps.map((rep) => (rep, agentCounts[rep.id] ?? 0)).toList();
  }

  List<UserModel> get unassignedAgents {
    return allUsers.where((user) {
      // THAY ĐỔI: Thêm điều kiện user không phải là Kế toán
      return !user.isAdmin &&
          !user.isSalesRep &&
          !user.isAccountant && // <-- THÊM DÒNG NÀY
          (user.salesRepId == null || user.salesRepId!.isEmpty);
    }).toList();
  }

  List<UserModel> get admins {
    return allUsers.where((user) => user.isAdmin).toList();
  }

  AdminUsersState copyWith({
    AdminUsersStatus? status,
    List<UserModel>? allUsers,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AdminUsersState(
      status: status ?? this.status,
      allUsers: allUsers ?? this.allUsers,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, allUsers, errorMessage];
}