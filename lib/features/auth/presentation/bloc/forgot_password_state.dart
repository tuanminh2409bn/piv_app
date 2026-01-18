part of 'forgot_password_cubit.dart';

enum ForgotPasswordStatus { initial, submitting, success, error }

class ForgotPasswordState {
  final String email;
  final ForgotPasswordStatus status;
  final String? errorMessage;

  const ForgotPasswordState({
    this.email = '',
    this.status = ForgotPasswordStatus.initial,
    this.errorMessage,
  });

  bool get isFormValid {
    return email.isNotEmpty && RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  ForgotPasswordState copyWith({
    String? email,
    ForgotPasswordStatus? status,
    String? errorMessage,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}
