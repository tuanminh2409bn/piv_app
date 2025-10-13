//lib/features/auth/presentation/bloc/login_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/auth/domain/repositories/auth_repository.dart';
import 'dart:developer' as developer;

part 'login_state.dart'; // Import LoginState

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _authRepository;

  LoginCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const LoginState()); // Trạng thái ban đầu

  // Hàm được gọi khi người dùng thay đổi email trên TextField
  void emailChanged(String value) {
    emit(state.copyWith(email: value, status: LoginStatus.initial, clearErrorMessage: true));
  }

  // Hàm được gọi khi người dùng thay đổi password trên TextField
  void passwordChanged(String value) {
    emit(state.copyWith(password: value, status: LoginStatus.initial, clearErrorMessage: true));
  }

  // Hàm được gọi khi người dùng nhấn nút Đăng nhập
  Future<void> logInWithCredentials() async {
    if (!state.isFormValid || state.status == LoginStatus.submitting) return;

    emit(state.copyWith(status: LoginStatus.submitting, clearErrorMessage: true));
    developer.log('LoginCubit: Attempting login with email: ${state.email}', name: 'LoginCubit');

    final result = await _authRepository.logInWithEmailAndPassword(
      email: state.email,
      password: state.password,
    );

    result.fold(
          (failure) {
        developer.log('LoginCubit: Login failed - ${failure.message}', name: 'LoginCubit');
        emit(state.copyWith(
          status: LoginStatus.error,
          errorMessage: failure.message,
        ));
      },
          (_) {
        // Đăng nhập thành công. AuthBloc sẽ tự động nhận biết sự thay đổi
        // trạng thái xác thực thông qua stream `user` từ AuthRepository
        // và cập nhật trạng thái toàn cục.
        // LoginCubit chỉ cần báo hiệu thành công ở đây.
        developer.log('LoginCubit: Login successful for email: ${state.email}', name: 'LoginCubit');
        emit(state.copyWith(status: LoginStatus.success));
      },
    );
  }
}
