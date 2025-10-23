// lib/features/admin/presentation/bloc/admin_users_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';

part 'admin_users_state.dart';

class AdminUsersCubit extends Cubit<AdminUsersState> {
  final AdminRepository _adminRepository;
  final AuthBloc _authBloc; // <--- THÊM DÒNG NÀY

  AdminUsersCubit({
    required AdminRepository adminRepository,
    required AuthBloc authBloc, // <--- THÊM DÒNG NÀY
  })  : _adminRepository = adminRepository,
        _authBloc = authBloc, // <--- THÊM DÒNG NÀY
        super(const AdminUsersState());

  // ... hàm fetchAndGroupUsers và updateUser giữ nguyên ...
  Future<void> fetchAndGroupUsers() async {
    if (state.status != AdminUsersStatus.success) {
      emit(state.copyWith(status: AdminUsersStatus.loading));
    }

    final result = await _adminRepository.getAllUsers();

    result.fold(
          (failure) {
        emit(state.copyWith(status: AdminUsersStatus.error, errorMessage: failure.message));
      },
          (users) {
        emit(state.copyWith(
          status: AdminUsersStatus.success,
          allUsers: users,
        ));
      },
    );
  }

  Future<void> updateUser(String userId, String role, String status) async {
    emit(state.copyWith(status: AdminUsersStatus.updating));

    final result = await _adminRepository.updateUser(userId, role, status);

    result.fold(
          (failure) {
        emit(state.copyWith(
          status: AdminUsersStatus.success,
          errorMessage: 'Cập nhật thất bại: ${failure.message}',
        ));
        emit(state.copyWith(clearErrorMessage: true));
      },
          (_) => fetchAndGroupUsers(),
    );
  }

  // --- SỬA ĐỔI HÀM NÀY ---
  Future<void> updateUserDebt({
    required String userId,
    required double newDebtAmount,
  }) async {
    // Lấy thông tin người dùng đang đăng nhập
    final authState = _authBloc.state;
    if (authState is! AuthAuthenticated) {
      emit(state.copyWith(
        status: AdminUsersStatus.success,
        errorMessage: 'Lỗi xác thực người dùng.',
      ));
      return;
    }

    emit(state.copyWith(status: AdminUsersStatus.updating));

    final result = await _adminRepository.updateUserDebt(
      userId: userId,
      newDebtAmount: newDebtAmount,
      updatedBy: authState.user.id, // Truyền ID người đang cập nhật
    );

    result.fold(
          (failure) {
        emit(state.copyWith(
          status: AdminUsersStatus.success,
          errorMessage: 'Cập nhật công nợ thất bại: ${failure.message}',
        ));
        emit(state.copyWith(clearErrorMessage: true));
      },
          (_) => fetchAndGroupUsers(),
    );
  }
}