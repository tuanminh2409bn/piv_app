//lib/features/auth/presentation/bloc/social_sign_in_state.dart

part of 'social_sign_in_cubit.dart';

enum SocialSignInStatus { initial, submitting, success, error }

class SocialSignInState extends Equatable {
  final SocialSignInStatus status;
  final String? errorMessage;

  const SocialSignInState({
    this.status = SocialSignInStatus.initial,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, errorMessage];

  SocialSignInState copyWith({
    SocialSignInStatus? status,
    String? errorMessage,
  }) {
    return SocialSignInState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
