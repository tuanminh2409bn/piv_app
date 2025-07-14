part of 'admin_users_cubit.dart';

enum AdminUsersStatus { initial, loading, success, error }

typedef SalesRepWithAgentCount = (UserModel salesRep, int agentCount);

class AdminUsersState extends Equatable {
  const AdminUsersState({
    this.status = AdminUsersStatus.initial,
    this.allUsers = const [], // ‼️ THÊM LẠI DANH SÁCH TỔNG
    this.errorMessage,
  });

  final AdminUsersStatus status;
  final List<UserModel> allUsers; // Danh sách tổng chứa tất cả người dùng
  final String? errorMessage;

  // --- GETTERS TỰ ĐỘNG LỌC TỪ `allUsers` ---

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
      return !user.isAdmin && !user.isSalesRep && (user.salesRepId == null || user.salesRepId!.isEmpty);
    }).toList();
  }

  List<UserModel> get admins {
    return allUsers.where((user) => user.isAdmin).toList();
  }

  AdminUsersState copyWith({
    AdminUsersStatus? status,
    List<UserModel>? allUsers,
    String? errorMessage,
  }) {
    return AdminUsersState(
      status: status ?? this.status,
      allUsers: allUsers ?? this.allUsers,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, allUsers, errorMessage];
}