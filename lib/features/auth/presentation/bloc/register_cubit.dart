//lib/features/auth/presentation/bloc/register_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/auth/domain/repositories/auth_repository.dart';
import 'dart:developer' as developer;

part 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final AuthRepository _authRepository;

  RegisterCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const RegisterState());

  void emailChanged(String value) {
    emit(state.copyWith(email: value, status: RegisterStatus.initial));
  }

  void passwordChanged(String value) {
    emit(state.copyWith(password: value, status: RegisterStatus.initial));
  }

  void confirmPasswordChanged(String value) {
    emit(state.copyWith(confirmPassword: value, status: RegisterStatus.initial));
  }

  void displayNameChanged(String value) {
    emit(state.copyWith(displayName: value, status: RegisterStatus.initial));
  }

  // ** PHƯƠNG THỨC MỚI **
  void referralCodeChanged(String value) {
    emit(state.copyWith(referralCode: value, status: RegisterStatus.initial));
  }

  Future<void> signUpWithCredentials() async {
    if (!state.isFormValid || state.status == RegisterStatus.submitting) return;

    emit(state.copyWith(status: RegisterStatus.submitting));
    developer.log('RegisterCubit: Attempting sign up for email: ${state.email}', name: 'RegisterCubit');

    final result = await _authRepository.signUp(
      email: state.email,
      password: state.password,
      displayName: state.displayName.isNotEmpty ? state.displayName : null,
      referralCode: state.referralCode.isNotEmpty ? state.referralCode : null, // << TRUYỀN referralCode
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
        developer.log('RegisterCubit: SignUp successful for email: ${state.email}', name: 'RegisterCubit');
        emit(state.copyWith(status: RegisterStatus.success));
      },
    );
  }
}
