// lib/features/auth/presentation/bloc/social_sign_in_state.dart

part of 'social_sign_in_cubit.dart';

// ========== THÊM ENUM NÀY ĐỂ ĐỊNH DANH CÁC NÚT ==========
enum SocialSignInProvider { none, google, facebook, apple, guest }
// =========================================================

class SocialSignInState extends Equatable {
  final SocialSignInStatus status;
  final String? errorMessage;
  // ========== THÊM THUỘC TÍNH MỚI NÀY ==========
  final SocialSignInProvider submissionProvider;
  // ===========================================

  const SocialSignInState({
    this.status = SocialSignInStatus.initial,
    this.errorMessage,
    // ========== THÊM VÀO CONSTRUCTOR ==========
    this.submissionProvider = SocialSignInProvider.none,
    // ========================================
  });

  SocialSignInState copyWith({
    SocialSignInStatus? status,
    String? errorMessage,
    // ========== THÊM VÀO COPYWITH ==========
    SocialSignInProvider? submissionProvider,
    // ======================================
  }) {
    return SocialSignInState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      // ========== THÊM VÀO COPYWITH ==========
      submissionProvider: submissionProvider ?? this.submissionProvider,
      // ======================================
    );
  }

  @override
  // ========== CẬP NHẬT PROPS ==========
  List<Object?> get props => [status, errorMessage, submissionProvider];
// ===================================
}

enum SocialSignInStatus { initial, submitting, success, error }