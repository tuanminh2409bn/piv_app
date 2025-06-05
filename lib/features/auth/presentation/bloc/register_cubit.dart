import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/auth/domain/repositories/auth_repository.dart';
import 'dart:developer' as developer;

part 'register_state.dart'; // Import RegisterState

class RegisterCubit extends Cubit<RegisterState> {
  final AuthRepository _authRepository;

  RegisterCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const RegisterState()); // Trạng thái ban đầu

  void emailChanged(String value) {
    emit(state.copyWith(email: value, status: RegisterStatus.initial, clearErrorMessage: true));
  }

  void passwordChanged(String value) {
    emit(state.copyWith(password: value, status: RegisterStatus.initial, clearErrorMessage: true));
  }

  void confirmPasswordChanged(String value) {
    emit(state.copyWith(confirmPassword: value, status: RegisterStatus.initial, clearErrorMessage: true));
  }

  void displayNameChanged(String value) {
    emit(state.copyWith(displayName: value, status: RegisterStatus.initial, clearErrorMessage: true));
  }

  Future<void> signUpWithCredentials() async {
    if (!state.isFormValid || state.status == RegisterStatus.submitting) return;

    emit(state.copyWith(status: RegisterStatus.submitting, clearErrorMessage: true));
    developer.log('RegisterCubit: Attempting sign up for email: ${state.email}', name: 'RegisterCubit');

    final result = await _authRepository.signUp(
      email: state.email,
      password: state.password,
      displayName: state.displayName.isNotEmpty ? state.displayName : null,
    );

    result.fold(
          (failure) {
        developer.log('RegisterCubit: SignUp failed - ${failure.message}', name: 'RegisterCubit');
        emit(state.copyWith(
          status: RegisterStatus.error,
          errorMessage: failure.message,
        ));
      },
          (_) {
        // Đăng ký thành công. AuthBloc sẽ tự động nhận biết sự thay đổi
        // trạng thái xác thực và cập nhật trạng thái toàn cục.
        // RegisterCubit chỉ cần báo hiệu thành công.
        developer.log('RegisterCubit: SignUp successful for email: ${state.email}', name: 'RegisterCubit');
        emit(state.copyWith(status: RegisterStatus.success));
        // Thông thường, sau khi đăng ký thành công, bạn sẽ muốn tự động đăng nhập người dùng.
        // AuthBloc đã xử lý việc này khi lắng nghe authStateChanges.
      },
    );
  }
}
