// Có thể đặt part of 'login_cubit.dart'; nếu login_cubit.dart ở cùng cấp
// Hoặc import 'login_cubit.dart' nếu ở file riêng
part of 'login_cubit.dart'; // Giả sử login_cubit.dart sẽ được tạo cùng cấp

// Enum để biểu diễn trạng thái của việc submit form
enum LoginStatus {
  initial, // Trạng thái ban đầu
  submitting, // Đang gửi yêu cầu đăng nhập
  success, // Đăng nhập thành công
  error, // Đăng nhập thất bại
}

class LoginState extends Equatable {
  final String email;
  final String password;
  final LoginStatus status;
  final String? errorMessage; // Thông báo lỗi nếu có

  const LoginState({
    this.email = '',
    this.password = '',
    this.status = LoginStatus.initial,
    this.errorMessage,
  });

  // Phương thức copyWith để dễ dàng tạo state mới dựa trên state cũ
  LoginState copyWith({
    String? email,
    String? password,
    LoginStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false, // Cờ để xóa errorMessage
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      status: status ?? this.status,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  // Getter để kiểm tra tính hợp lệ của form (ví dụ đơn giản)
  bool get isFormValid => email.isNotEmpty && password.isNotEmpty;

  @override
  List<Object?> get props => [email, password, status, errorMessage];
}
