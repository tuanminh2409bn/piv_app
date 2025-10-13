// lib/features/auth/presentation/bloc/auth_event.dart
part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthAppStarted extends AuthEvent {}

class AuthUserChanged extends AuthEvent {
  final UserModel user;

  const AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}

// --- THÊM SỰ KIỆN MỚI ---
/// Sự kiện được gửi từ các Cubit khác để yêu cầu AuthBloc làm mới thông tin người dùng
class AuthUserRefreshRequested extends AuthEvent {}

class AuthLogoutRequested extends AuthEvent {}