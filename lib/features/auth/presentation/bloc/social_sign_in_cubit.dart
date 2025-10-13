// lib/features/auth/presentation/bloc/social_sign_in_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/auth/domain/repositories/auth_repository.dart';

part 'social_sign_in_state.dart';

class SocialSignInCubit extends Cubit<SocialSignInState> {
  final AuthRepository _authRepository;
  SocialSignInCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const SocialSignInState());

  // ***** THAY ĐỔI TOÀN BỘ LOGIC CÁC HÀM DƯỚI ĐÂY *****
  Future<void> logInWithGoogle() async {
    emit(state.copyWith(status: SocialSignInStatus.submitting, submissionProvider: SocialSignInProvider.google));
    final result = await _authRepository.signInWithGoogle();
    if (isClosed) return;
    result.fold(
          (failure) => emit(state.copyWith(status: SocialSignInStatus.error, errorMessage: failure.message, submissionProvider: SocialSignInProvider.none)),
          (signInResult) => emit(state.copyWith(status: SocialSignInStatus.success, isNewUser: signInResult.isNewUser, submissionProvider: SocialSignInProvider.none)),
    );
  }

  Future<void> logInWithFacebook() async {
    emit(state.copyWith(status: SocialSignInStatus.submitting, submissionProvider: SocialSignInProvider.facebook));
    final result = await _authRepository.signInWithFacebook();
    if (isClosed) return;
    result.fold(
          (failure) => emit(state.copyWith(status: SocialSignInStatus.error, errorMessage: failure.message, submissionProvider: SocialSignInProvider.none)),
          (signInResult) => emit(state.copyWith(status: SocialSignInStatus.success, isNewUser: signInResult.isNewUser, submissionProvider: SocialSignInProvider.none)),
    );
  }

  Future<void> logInWithApple() async {
    emit(state.copyWith(status: SocialSignInStatus.submitting, submissionProvider: SocialSignInProvider.apple));
    final result = await _authRepository.signInWithApple();
    if (isClosed) return;
    result.fold(
          (failure) => emit(state.copyWith(status: SocialSignInStatus.error, errorMessage: failure.message, submissionProvider: SocialSignInProvider.none)),
          (signInResult) => emit(state.copyWith(status: SocialSignInStatus.success, isNewUser: signInResult.isNewUser, submissionProvider: SocialSignInProvider.none)),
    );
  }

  Future<void> logInAsGuest() async {
    emit(state.copyWith(status: SocialSignInStatus.submitting, submissionProvider: SocialSignInProvider.guest));
    final result = await _authRepository.signInAnonymously();
    if (isClosed) return;
    result.fold(
          (failure) => emit(state.copyWith(status: SocialSignInStatus.error, errorMessage: failure.message, submissionProvider: SocialSignInProvider.none)),
          (_) => emit(state.copyWith(status: SocialSignInStatus.success, isNewUser: false, submissionProvider: SocialSignInProvider.none)), // Khách không bao giờ là user mới cần chờ duyệt
    );
  }
}