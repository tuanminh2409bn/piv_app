import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_repository.dart';
import 'dart:developer' as developer;

part 'admin_users_state.dart';

class AdminUsersCubit extends Cubit<AdminUsersState> {
  final AdminRepository _adminRepository;

  AdminUsersCubit({required AdminRepository adminRepository})
      : _adminRepository = adminRepository,
        super(const AdminUsersState());

  /// Tải tất cả người dùng trong hệ thống
  Future<void> fetchAllUsers() async {
    emit(state.copyWith(status: AdminUsersStatus.loading));
    developer.log('AdminUsersCubit: Fetching all users...', name: 'AdminUsersCubit');

    final result = await _adminRepository.getAllUsers();

    result.fold(
          (failure) {
        emit(state.copyWith(status: AdminUsersStatus.error, errorMessage: failure.message));
      },
          (users) {
        // Sau khi tải, áp dụng lại bộ lọc hiện tại
        emit(state.copyWith(
          status: AdminUsersStatus.success,
          allUsers: users,
        ));
        filterUsers(state.currentFilter);
      },
    );
  }

  /// Cập nhật vai trò và trạng thái của người dùng
  Future<void> updateUser(String userId, String newRole, String newStatus) async {
    // Không emit loading để tránh giật màn hình
    final result = await _adminRepository.updateUser(userId, newRole, newStatus);
    result.fold(
          (failure) {
        emit(state.copyWith(status: AdminUsersStatus.error, errorMessage: failure.message));
      },
          (_) {
        // Tải lại toàn bộ danh sách để đảm bảo dữ liệu mới nhất
        fetchAllUsers();
      },
    );
  }

  /// Lọc danh sách người dùng theo trạng thái
  void filterUsers(String filter) {
    List<UserModel> filteredList;
    switch (filter) {
      case 'pending_approval':
        filteredList = state.allUsers.where((user) => user.status == 'pending_approval').toList();
        break;
      case 'active':
        filteredList = state.allUsers.where((user) => user.status == 'active').toList();
        break;
      default: // 'all'
        filteredList = state.allUsers;
    }
    emit(state.copyWith(filteredUsers: filteredList, currentFilter: filter));
  }
}
