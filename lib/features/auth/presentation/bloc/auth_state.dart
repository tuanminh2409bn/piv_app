//lib/features/auth/presentation/bloc/auth_state.dart

part of 'auth_bloc.dart'; // Sẽ tạo file auth_bloc.dart sau

// Lớp cơ sở cho tất cả các trạng thái xác thực
abstract class AuthState extends Equatable {
  final UserModel user; // UserModel hiện tại, có thể là UserModel.empty

  const AuthState({this.user = UserModel.empty});

  @override
  List<Object?> get props => [user];
}

// Trạng thái khởi tạo, chưa xác định
class AuthInitial extends AuthState {}

// Trạng thái người dùng đã được xác thực (đăng nhập thành công)
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required super.user}); // Yêu cầu user không được rỗng

  @override
  List<Object?> get props => [user];
}

// Trạng thái người dùng chưa được xác thực (chưa đăng nhập hoặc đã đăng xuất)
class AuthUnauthenticated extends AuthState {}

// (Tùy chọn) Trạng thái đang xử lý (ví dụ: đang đăng xuất)
class AuthLoading extends AuthState {}

// (Tùy chọn) Trạng thái lỗi xác thực chung
class AuthFailureState extends AuthState {
  final String message;
  const AuthFailureState(this.message, {super.user});

  @override
  List<Object?> get props => [message, user];
}
