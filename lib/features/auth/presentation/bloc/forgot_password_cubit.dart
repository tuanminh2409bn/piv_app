import 'package:bloc/bloc.dart';
import 'package:piv_app/features/auth/domain/repositories/auth_repository.dart';

part 'forgot_password_state.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final AuthRepository _authRepository;

  ForgotPasswordCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const ForgotPasswordState());

  void emailChanged(String value) {
    emit(state.copyWith(email: value, status: ForgotPasswordStatus.initial));
  }

  Future<void> submit() async {
    if (!state.isFormValid) return;

    emit(state.copyWith(status: ForgotPasswordStatus.submitting));

    final result = await _authRepository.sendPasswordResetEmail(email: state.email);

    result.fold(
      (failure) => emit(state.copyWith(
        status: ForgotPasswordStatus.error,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(status: ForgotPasswordStatus.success)),
    );
  }
}
