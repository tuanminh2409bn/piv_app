// lib/features/auth/presentation/bloc/auth_bloc.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/auth/domain/repositories/auth_repository.dart';
// --- THÊM IMPORT MỚI ---
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'dart:developer' as developer;

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  // --- THÊM REPOSITORY MỚI ---
  final UserProfileRepository _userProfileRepository;
  StreamSubscription<UserModel>? _userSubscription;

  AuthBloc({
    required AuthRepository authRepository,
    required UserProfileRepository userProfileRepository, // <<< Thêm vào constructor
  })  : _authRepository = authRepository,
        _userProfileRepository = userProfileRepository, // <<< Gán giá trị
        super(AuthInitial()) {
    _userSubscription = _authRepository.user.listen(
          (user) => add(AuthUserChanged(user)),
    );

    on<AuthAppStarted>(_onAppStarted);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthUserRefreshRequested>(_onUserRefreshRequested);
  }

  // --- HÀM _onUserRefreshRequested ĐÃ ĐƯỢC SỬA ---
  Future<void> _onUserRefreshRequested(
      AuthUserRefreshRequested event, Emitter<AuthState> emit) async {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      developer.log('AuthBloc: Refresh requested for user ${currentState.user.id}', name: 'AuthBloc');
      // Gọi đến đúng repository
      final result = await _userProfileRepository.getUserProfile(currentState.user.id);
      result.fold(
            (failure) {
          developer.log('AuthBloc: User refresh failed: ${failure.message}', name: 'AuthBloc');
        },
            (user) {
          add(AuthUserChanged(user));
        },
      );
    }
  }

  // Các hàm còn lại giữ nguyên
  Future<void> _onAppStarted(AuthAppStarted event, Emitter<AuthState> emit) async { try { final result = await _authRepository.getCurrentUser(); result.fold( (failure) => emit(AuthUnauthenticated()), (user) { if (user.isNotEmpty) { emit(AuthAuthenticated(user: user)); } else { emit(AuthUnauthenticated()); } } ); } catch (_) { emit(AuthUnauthenticated()); } }
  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) { developer.log('AuthBloc: User changed - ${event.user.email}, isEmpty: ${event.user.isEmpty}', name: 'AuthBloc'); if (event.user.isNotEmpty) { emit(AuthAuthenticated(user: event.user)); } else { emit(AuthUnauthenticated()); } }
  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async { emit(AuthLoading()); await _authRepository.logOut(); }
  @override
  Future<void> close() { _userSubscription?.cancel(); return super.close(); }
}