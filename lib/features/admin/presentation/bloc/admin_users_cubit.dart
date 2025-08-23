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

  Future<void> fetchAndGroupUsers() async {
    // Giữ trạng thái cũ nếu đang tải lại, chỉ hiện loading lần đầu
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
    // SỬA LỖI: Phát ra trạng thái updating để UI có thể phản hồi (ví dụ: hiện loading)
    emit(state.copyWith(status: AdminUsersStatus.updating));

    final result = await _adminRepository.updateUser(userId, role, status);

    result.fold(
          (failure) {
        // Nếu lỗi, quay lại trạng thái success với dữ liệu cũ và thông báo lỗi
        emit(state.copyWith(
          status: AdminUsersStatus.success, // Quay lại success để UI không bị treo ở màn hình lỗi
          errorMessage: 'Cập nhật thất bại: ${failure.message}', // Có thể hiển thị SnackBar từ lỗi này
        ));
      },
      // Nếu thành công, gọi lại fetchAndGroupUsers để đảm bảo dữ liệu là mới nhất
          (_) => fetchAndGroupUsers(),
    );
  }
}