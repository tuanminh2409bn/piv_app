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

  Future<void> logInWithGoogle() async {
    emit(state.copyWith(status: SocialSignInStatus.submitting));
    final result = await _authRepository.signInWithGoogle();
    result.fold(
          (failure) => emit(state.copyWith(status: SocialSignInStatus.error, errorMessage: failure.message)),
          (_) => emit(state.copyWith(status: SocialSignInStatus.success)),
    );
  }

  Future<void> logInWithFacebook() async {
    emit(state.copyWith(status: SocialSignInStatus.submitting));
    final result = await _authRepository.signInWithFacebook();
    result.fold(
          (failure) => emit(state.copyWith(status: SocialSignInStatus.error, errorMessage: failure.message)),
          (_) => emit(state.copyWith(status: SocialSignInStatus.success)),
    );
  }

  // ====================== BẮT ĐẦU SỬA ĐỔI ======================
  Future<void> logInWithApple() async {
    emit(state.copyWith(status: SocialSignInStatus.submitting));
    final result = await _authRepository.signInWithApple();
    result.fold(
          (failure) => emit(state.copyWith(status: SocialSignInStatus.error, errorMessage: failure.message)),
          (_) => emit(state.copyWith(status: SocialSignInStatus.success)),
    );
  }
// ======================= KẾT THÚC SỬA ĐỔI =======================
}