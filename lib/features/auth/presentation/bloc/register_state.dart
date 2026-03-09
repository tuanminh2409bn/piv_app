//lib/features/auth/presentation/bloc/register_state.dart

part of 'register_cubit.dart';

enum RegisterStatus { initial, submitting, success, error }

class RegisterState extends Equatable {
  final String email;
  final String password;
  final String confirmPassword;
  final String displayName;
  final String referralCode;
  final String phoneNumber;
  final String idCardOrTaxId;
  final String dob;
  final String currentAddress;
  final RegisterStatus status;
  final String? errorMessage;

  const RegisterState({
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.displayName = '',
    this.referralCode = '',
    this.phoneNumber = '',
    this.idCardOrTaxId = '',
    this.dob = '',
    this.currentAddress = '',
    this.status = RegisterStatus.initial,
    this.errorMessage,
  });

  bool get passwordsMatch => password == confirmPassword;
  bool get isFormValid =>
      email.isNotEmpty &&
      password.isNotEmpty &&
      passwordsMatch &&
      password.length >= 6 &&
      displayName.isNotEmpty &&
      phoneNumber.isNotEmpty &&
      idCardOrTaxId.isNotEmpty &&
      dob.isNotEmpty &&
      currentAddress.isNotEmpty;

  RegisterState copyWith({
    String? email,
    String? password,
    String? confirmPassword,
    String? displayName,
    String? referralCode,
    String? phoneNumber,
    String? idCardOrTaxId,
    String? dob,
    String? currentAddress,
    RegisterStatus? status,
    String? errorMessage,
  }) {
    return RegisterState(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      displayName: displayName ?? this.displayName,
      referralCode: referralCode ?? this.referralCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      idCardOrTaxId: idCardOrTaxId ?? this.idCardOrTaxId,
      dob: dob ?? this.dob,
      currentAddress: currentAddress ?? this.currentAddress,
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
    referralCode,
    phoneNumber,
    idCardOrTaxId,
    dob,
    currentAddress,
    status,
    errorMessage,
  ];
}
