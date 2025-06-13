part of 'admin_users_cubit.dart';

enum AdminUsersStatus { initial, loading, success, error }

class AdminUsersState extends Equatable {
  final AdminUsersStatus status;
  // Danh sách đầy đủ tất cả người dùng
  final List<UserModel> allUsers;
  // Danh sách người dùng đã được lọc (dựa trên tìm kiếm hoặc bộ lọc trạng thái)
  final List<UserModel> filteredUsers;
  final String? errorMessage;
  // Trạng thái bộ lọc hiện tại, ví dụ: 'all', 'pending_approval'
  final String currentFilter;

  const AdminUsersState({
    this.status = AdminUsersStatus.initial,
    this.allUsers = const [],
    this.filteredUsers = const [],
    this.errorMessage,
    this.currentFilter = 'all',
  });

  @override
  List<Object?> get props => [status, allUsers, filteredUsers, errorMessage, currentFilter];

  AdminUsersState copyWith({
    AdminUsersStatus? status,
    List<UserModel>? allUsers,
    List<UserModel>? filteredUsers,
    String? errorMessage,
    String? currentFilter,
  }) {
    return AdminUsersState(
      status: status ?? this.status,
      allUsers: allUsers ?? this.allUsers,
      filteredUsers: filteredUsers ?? this.filteredUsers,
      errorMessage: errorMessage ?? this.errorMessage,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }
}
