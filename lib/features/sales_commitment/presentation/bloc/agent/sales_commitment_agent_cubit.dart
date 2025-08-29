// lib/features/sales_commitment/presentation/bloc/agent/sales_commitment_agent_cubit.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/data/models/sales_commitment_model.dart';
import 'package:piv_app/features/sales_commitment/domain/repositories/sales_commitment_repository.dart';

part 'sales_commitment_agent_state.dart';

class SalesCommitmentAgentCubit extends Cubit<SalesCommitmentAgentState> {
  final SalesCommitmentRepository _repository;
  final AuthBloc _authBloc;
  StreamSubscription? _authSubscription;
  StreamSubscription? _commitmentSubscription;
  String _currentUserId = '';

  SalesCommitmentAgentCubit({
    required SalesCommitmentRepository repository,
    required AuthBloc authBloc,
  })  : _repository = repository,
        _authBloc = authBloc,
        super(const SalesCommitmentAgentState()) {
    _authSubscription = _authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        _setUserIdAndListen(authState.user.id);
      } else {
        _setUserIdAndListen('');
      }
    });
    // Xử lý trạng thái ban đầu
    final initialState = _authBloc.state;
    if (initialState is AuthAuthenticated) {
      _setUserIdAndListen(initialState.user.id);
    }
  }

  void _setUserIdAndListen(String userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    _commitmentSubscription?.cancel();

    if (userId.isEmpty) {
      emit(const SalesCommitmentAgentState());
      return;
    }

    emit(state.copyWith(status: SalesCommitmentAgentStatus.loading));
    _commitmentSubscription = _repository.watchActiveCommitmentForUser(userId).listen(
          (commitment) {
        emit(state.copyWith(
          status: SalesCommitmentAgentStatus.success,
          activeCommitment: commitment,
          forceCommitmentToNull: commitment == null,
        ));
      },
      onError: (error) {
        emit(state.copyWith(
          status: SalesCommitmentAgentStatus.error,
          errorMessage: 'Lỗi tải dữ liệu cam kết.',
        ));
      },
    );
  }

  Future<void> createCommitment({
    required double targetAmount,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    emit(state.copyWith(status: SalesCommitmentAgentStatus.loading));
    final result = await _repository.createSalesCommitment(
      targetAmount: targetAmount,
      startDate: startDate,
      endDate: endDate,
    );
    result.fold(
          (failure) => emit(state.copyWith(
        status: SalesCommitmentAgentStatus.error,
        errorMessage: failure.message,
      )),
          (_) => emit(state.copyWith(status: SalesCommitmentAgentStatus.success)),
    );
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _commitmentSubscription?.cancel();
    return super.close();
  }
}