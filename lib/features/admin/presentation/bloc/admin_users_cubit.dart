// lib/features/admin/presentation/bloc/admin_users_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/admin/data/models/discount_policy_model.dart';
import 'dart:async';

part 'admin_users_state.dart';

class AdminUsersCubit extends Cubit<AdminUsersState> {
  final AdminRepository _adminRepository;
  final AuthBloc _authBloc;
  StreamSubscription? _usersSubscription;

  AdminUsersCubit({
    required AdminRepository adminRepository,
    required AuthBloc authBloc,
  })  : _adminRepository = adminRepository,
        _authBloc = authBloc,
        super(const AdminUsersState()) {
    _watchUsers(); // Bắt đầu lắng nghe ngay khi khởi tạo
  }

  void _watchUsers() {
    emit(state.copyWith(status: AdminUsersStatus.loading));
    _usersSubscription?.cancel();
    _usersSubscription = _adminRepository.watchAllUsers().listen(
      (users) {
        emit(state.copyWith(
          status: AdminUsersStatus.success,
          allUsers: users,
        ));
      },
      onError: (error) {
        emit(state.copyWith(
          status: AdminUsersStatus.error,
          errorMessage: error.toString(),
        ));
      },
    );
  }

  // Giữ lại hàm này để tương thích, nhưng thực chất dữ liệu sẽ tự động cập nhật
  Future<void> fetchAndGroupUsers() async {
    // Không cần làm gì vì _watchUsers đã xử lý
  }

  @override
  Future<void> close() {
    _usersSubscription?.cancel();
    return super.close();
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

    final currentUser = authState.user;
    emit(state.copyWith(status: AdminUsersStatus.updating));

    if (currentUser.isAdmin) {
      // Admin cập nhật trực tiếp
      final result = await _adminRepository.updateUserDebt(
        userId: userId,
        newDebtAmount: newDebtAmount,
        updatedBy: currentUser.id,
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
    } else {
      // Nhân viên kinh doanh / Kế toán gửi yêu cầu phê duyệt
      final targetUser = state.allUsers.firstWhere(
        (u) => u.id == userId,
        orElse: () => UserModel.empty,
      );

      if (targetUser.isEmpty) {
        emit(state.copyWith(
          status: AdminUsersStatus.success,
          errorMessage: 'Không tìm thấy thông tin khách hàng.',
        ));
        return;
      }

      final result = await _adminRepository.createDebtUpdateRequest(
        userId: userId,
        userName: targetUser.displayName ?? targetUser.email ?? 'Ẩn danh',
        oldDebtAmount: targetUser.debtAmount,
        newDebtAmount: newDebtAmount,
        requestedBy: currentUser.id,
        requestedByName: currentUser.displayName ?? currentUser.email ?? 'Nhân viên',
      );

      result.fold(
            (failure) {
          emit(state.copyWith(
            status: AdminUsersStatus.success,
            errorMessage: 'Gửi yêu cầu thất bại: ${failure.message}',
          ));
          emit(state.copyWith(clearErrorMessage: true));
        },
            (_) {
          emit(state.copyWith(
            status: AdminUsersStatus.success,
            errorMessage: 'Yêu cầu cập nhật công nợ đã được gửi tới Admin phê duyệt.',
          ));
          emit(state.copyWith(clearErrorMessage: true));
          fetchAndGroupUsers();
        },
      );
    }
  }

  Future<void> updateUserDiscountConfig({
    required String userId,
    required bool enabled,
    required AgentPolicy policy,
  }) async {
    emit(state.copyWith(status: AdminUsersStatus.updating));
    final result = await _adminRepository.updateUserDiscountConfig(
      userId: userId,
      enabled: enabled,
      policy: policy,
    );
    result.fold(
          (failure) {
        emit(state.copyWith(
          status: AdminUsersStatus.success,
          errorMessage: 'Cập nhật chiết khấu thất bại: ${failure.message}',
        ));
        emit(state.copyWith(clearErrorMessage: true));
      },
          (_) => fetchAndGroupUsers(),
    );
  }
}