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

  /// Lấy tất cả người dùng và cập nhật vào state.
  Future<void> fetchAndGroupUsers() async {
    emit(state.copyWith(status: AdminUsersStatus.loading));

    final result = await _adminRepository.getAllUsers();

    result.fold(
          (failure) {
        emit(state.copyWith(status: AdminUsersStatus.error, errorMessage: failure.message));
      },
          (users) {
        // Chỉ cần đưa danh sách tổng vào state. Việc phân loại do state tự xử lý.
        emit(state.copyWith(
          status: AdminUsersStatus.success,
          allUsers: users,
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