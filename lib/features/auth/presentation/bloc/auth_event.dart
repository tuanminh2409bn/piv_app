part of 'auth_bloc.dart'; // Sẽ tạo file auth_bloc.dart sau

// Lớp cơ sở cho tất cả các sự kiện xác thực
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// Sự kiện được gửi khi ứng dụng khởi động để kiểm tra trạng thái đăng nhập ban đầu
class AuthAppStarted extends AuthEvent {}

// Sự kiện được gửi khi trạng thái người dùng từ AuthRepository thay đổi
// (ví dụ: người dùng đăng nhập hoặc đăng xuất)
class AuthUserChanged extends AuthEvent {
  final UserModel user; // UserModel mới từ AuthRepository

  const AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}

// Sự kiện yêu cầu đăng xuất
class AuthLogoutRequested extends AuthEvent {}

// (Các sự kiện cho đăng nhập/đăng ký sẽ nằm trong các BLoC riêng, ví dụ: LoginBloc, RegisterBloc)
// Tuy nhiên, nếu bạn muốn AuthBloc xử lý luôn cả việc này thì có thể thêm ở đây.
// Để đơn giản và tách bạch, chúng ta sẽ có các BLoC nhỏ hơn cho từng form.
// AuthBloc chủ yếu sẽ quản lý trạng thái xác thực toàn cục.
