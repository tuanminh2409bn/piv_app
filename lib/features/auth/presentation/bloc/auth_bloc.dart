import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:dartz/dartz.dart'; // Cho unit
import 'dart:developer' as developer;


part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<UserModel>? _userSubscription; // Để lắng nghe thay đổi user từ repository

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) { // Trạng thái ban đầu là AuthInitial

    // Lắng nghe stream user từ AuthRepository
    // Khi có UserModel mới, gửi sự kiện AuthUserChanged
    _userSubscription = _authRepository.user.listen(
          (user) => add(AuthUserChanged(user)),
    );

    // Xử lý các sự kiện
    on<AuthAppStarted>(_onAppStarted);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  // Xử lý sự kiện AuthAppStarted
  Future<void> _onAppStarted(
      AuthAppStarted event, Emitter<AuthState> emit) async {
    // Khi app khởi động, cố gắng lấy người dùng hiện tại
    // Điều này hữu ích nếu stream `_authRepository.user` chưa kịp phát giá trị đầu tiên
    // hoặc để xử lý trường hợp app bị kill và khởi động lại.
    // Tuy nhiên, với việc lắng nghe `authStateChanges` trong `AuthRepositoryImpl`
    // và `_authRepository.user.listen` ở đây, trạng thái sẽ sớm được cập nhật.
    // Việc gọi getCurrentUser ở đây có thể là thừa, nhưng để chắc chắn.
    try {
      final result = await _authRepository.getCurrentUser();
      result.fold(
              (failure) => emit(AuthUnauthenticated()), // Nếu lỗi, coi như chưa đăng nhập
              (user) {
            if (user.isNotEmpty) {
              emit(AuthAuthenticated(user: user));
            } else {
              emit(AuthUnauthenticated());
            }
          }
      );
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  // Xử lý sự kiện AuthUserChanged
  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    developer.log('AuthBloc: User changed - ${event.user.email}, isEmpty: ${event.user.isEmpty}', name: 'AuthBloc');
    if (event.user.isNotEmpty) {
      emit(AuthAuthenticated(user: event.user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  // Xử lý sự kiện AuthLogoutRequested
  Future<void> _onLogoutRequested(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading()); // (Tùy chọn) Hiển thị trạng thái loading khi đăng xuất
    final result = await _authRepository.logOut();
    result.fold(
            (failure) {
          // Nếu đăng xuất thất bại, có thể vẫn giữ trạng thái đăng nhập
          // hoặc phát ra một lỗi cụ thể. Hiện tại, chúng ta sẽ dựa vào
          // stream `user` từ repository để cập nhật lại trạng thái.
          // Nếu stream `user` không phát UserModel.empty, trạng thái có thể không đổi.
          // Tuy nhiên, _authRepository.logOut() thành công sẽ trigger authStateChanges -> UserModel.empty
          developer.log('AuthBloc: Logout failed - ${failure.message}', name: 'AuthBloc');
          // Có thể emit một AuthFailureState ở đây nếu cần
          // emit(AuthFailureState(failure.message, user: state.user));
          // Hoặc đơn giản là chờ authStateChanges cập nhật
          // Nếu logout thành công, authStateChanges sẽ phát UserModel.empty và _onUserChanged sẽ emit AuthUnauthenticated
        },
            (_) {
          // Đăng xuất thành công, authStateChanges sẽ phát UserModel.empty
          // và _onUserChanged sẽ emit AuthUnauthenticated.
          // Không cần emit(AuthUnauthenticated()) ở đây trực tiếp.
          developer.log('AuthBloc: Logout successful', name: 'AuthBloc');
        }
    );
  }

  // Đóng stream subscription khi BLoC bị đóng
  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
