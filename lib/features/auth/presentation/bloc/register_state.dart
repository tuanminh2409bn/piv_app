// Giả sử register_cubit.dart sẽ được tạo cùng cấp
part of 'register_cubit.dart';

// Enum để biểu diễn trạng thái của việc submit form đăng ký
enum RegisterStatus {
  initial, // Trạng thái ban đầu
  submitting, // Đang gửi yêu cầu đăng ký
  success, // Đăng ký thành công
  error, // Đăng ký thất bại
}

class RegisterState extends Equatable {
  final String email;
  final String password;
  final String confirmPassword;
  final String displayName; // Tên hiển thị, có thể để trống
  final RegisterStatus status;
  final String? errorMessage;

  const RegisterState({
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.displayName = '',
    this.status = RegisterStatus.initial,
    this.errorMessage,
  });

  // Kiểm tra xem mật khẩu và xác nhận mật khẩu có khớp không
  bool get passwordsMatch => password == confirmPassword;

  // Kiểm tra tính hợp lệ của form (ví dụ cơ bản)
  bool get isFormValid =>
      email.isNotEmpty &&
          password.isNotEmpty &&
          confirmPassword.isNotEmpty &&
          passwordsMatch &&
          password.length >= 6; // Yêu cầu mật khẩu tối thiểu 6 ký tự

  RegisterState copyWith({
    String? email,
    String? password,
    String? confirmPassword,
    String? displayName,
    RegisterStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return RegisterState(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    email,
    password,
    confirmPassword,
    displayName,
    status,
    errorMessage,
  ];
}
