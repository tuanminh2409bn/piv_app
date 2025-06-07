part of 'profile_cubit.dart'; // Sẽ tạo file profile_cubit.dart ngay sau đây

enum ProfileStatus {
  initial,    // Trạng thái ban đầu
  loading,    // Đang tải thông tin hồ sơ
  success,    // Tải/Cập nhật thành công
  error,      // Có lỗi xảy ra
  updating,   // Đang cập nhật thông tin
}

class ProfileState extends Equatable {
  final UserModel user; // Thông tin người dùng hiện tại
  final ProfileStatus status;
  final String? errorMessage;
  // Cờ để biết liệu có đang ở chế độ chỉnh sửa hay không
  final bool isEditing;

  const ProfileState({
    this.user = UserModel.empty, // Khởi tạo với người dùng rỗng
    this.status = ProfileStatus.initial,
    this.errorMessage,
    this.isEditing = false,
  });

  ProfileState copyWith({
    UserModel? user,
    ProfileStatus? status,
    String? errorMessage,
    bool? isEditing,
    bool clearErrorMessage = false,
  }) {
    return ProfileState(
      user: user ?? this.user,
      status: status ?? this.status,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      isEditing: isEditing ?? this.isEditing,
    );
  }

  @override
  List<Object?> get props => [user, status, errorMessage, isEditing];
}
