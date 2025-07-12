import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_repository.dart';

part 'admin_users_state.dart';

class AdminUsersCubit extends Cubit<AdminUsersState> {
  final AdminRepository _adminRepository;

  AdminUsersCubit({required AdminRepository adminRepository})
      : _adminRepository = adminRepository,
        super(const AdminUsersState());

  /// Lấy tất cả người dùng và phân loại họ vào các nhóm tương ứng.
  Future<void> fetchAndGroupUsers() async {
    emit(state.copyWith(status: AdminUsersStatus.loading));

    final result = await _adminRepository.getAllUsers(); // Dùng hàm có sẵn trong repo của bạn

    result.fold(
          (failure) {
        emit(state.copyWith(status: AdminUsersStatus.error, errorMessage: failure.message));
      },
          (allUsers) {
        // --- LOGIC PHÂN LOẠI VÀ ĐẾM ---
        final List<UserModel> reps = [];
        final List<UserModel> agents = [];
        final List<UserModel> admins = [];

        for (final user in allUsers) {
          if (user.isSalesRep) {
            reps.add(user);
          } else if (user.isAdmin) {
            admins.add(user);
          } else {
            agents.add(user);
          }
        }

        final agentCounts = <String, int>{};
        for (final agent in agents) {
          if (agent.salesRepId != null && agent.salesRepId!.isNotEmpty) {
            agentCounts[agent.salesRepId!] = (agentCounts[agent.salesRepId] ?? 0) + 1;
          }
        }

        final List<SalesRepWithAgentCount> salesRepsWithCount = reps.map((rep) {
          return (rep, agentCounts[rep.id] ?? 0);
        }).toList();

        final unassigned = agents.where((agent) => agent.salesRepId == null || agent.salesRepId!.isEmpty).toList();

        emit(state.copyWith(
          status: AdminUsersStatus.success,
          salesReps: salesRepsWithCount,
          unassignedAgents: unassigned,
          admins: admins,
        ));
      },
    );
  }

  /// Cập nhật người dùng và tải lại toàn bộ danh sách.
  Future<void> updateUser(String userId, String role, String status) async {
    final result = await _adminRepository.updateUser(userId, role, status);
    result.fold(
          (failure) {
        emit(state.copyWith(status: AdminUsersStatus.error, errorMessage: failure.message));
      },
          (_) => fetchAndGroupUsers(),
    );
  }
}