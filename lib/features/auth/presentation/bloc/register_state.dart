//lib/features/auth/presentation/bloc/register_state.dart

part of 'register_cubit.dart';

enum RegisterStatus { initial, submitting, success, error }

class RegisterState extends Equatable {
  final String email;
  final String password;
  final String confirmPassword;
  final String displayName;
  final String referralCode; // << THÊM TRƯỜNG NÀY
  final RegisterStatus status;
  final String? errorMessage;

  const RegisterState({
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.displayName = '',
    this.referralCode = '', // << GIÁ TRỊ MẶC ĐỊNH
    this.status = RegisterStatus.initial,
    this.errorMessage,
  });

  bool get passwordsMatch => password == confirmPassword;
  bool get isFormValid =>
      email.isNotEmpty && password.isNotEmpty && passwordsMatch && password.length >= 6;

  RegisterState copyWith({
    String? email,
    String? password,
    String? confirmPassword,
    String? displayName,
    String? referralCode, // << THÊM VÀO COPYWITH
    RegisterStatus? status,
    String? errorMessage,
  }) {
    return RegisterState(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      displayName: displayName ?? this.displayName,
      referralCode: referralCode ?? this.referralCode, // << GÁN GIÁ TRỊ
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    email,
    password,
    confirmPassword,
    displayName,
    referralCode, // << THÊM VÀO PROPS
    status,
    errorMessage,
  ];
}
