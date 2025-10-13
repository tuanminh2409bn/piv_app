// lib/features/auth/presentation/bloc/social_sign_in_state.dart

part of 'social_sign_in_cubit.dart';

enum SocialSignInStatus { initial, submitting, success, error }
enum SocialSignInProvider { none, google, facebook, apple, guest }

class SocialSignInState extends Equatable {
  final SocialSignInStatus status;
  final String? errorMessage;
  final SocialSignInProvider submissionProvider;
  final bool isNewUser; // THÊM DÒNG NÀY

  const SocialSignInState({
    this.status = SocialSignInStatus.initial,
    this.errorMessage,
    this.submissionProvider = SocialSignInProvider.none,
    this.isNewUser = false, // THÊM DÒNG NÀY
  });

  SocialSignInState copyWith({
    SocialSignInStatus? status,
    String? errorMessage,
    SocialSignInProvider? submissionProvider,
    bool? isNewUser, // THÊM DÒNG NÀY
  }) {
    return SocialSignInState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      submissionProvider: submissionProvider ?? this.submissionProvider,
      isNewUser: isNewUser ?? this.isNewUser, // THÊM DÒNG NÀY
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, submissionProvider, isNewUser]; // CẬP NHẬT DÒNG NÀY
}