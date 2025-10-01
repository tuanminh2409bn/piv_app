import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'dart:async';

part 'sales_rep_state.dart';

class SalesRepCubit extends Cubit<SalesRepState> {
  final AdminRepository _adminRepository;
  final AuthBloc _authBloc;
  StreamSubscription? _authSubscription;
  String _currentSalesRepId = '';

  SalesRepCubit({
    required AdminRepository adminRepository,
    required AuthBloc authBloc,
  })  : _adminRepository = adminRepository,
        _authBloc = authBloc,
        super(const SalesRepState()) {
    _authSubscription = _authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated && authState.user.isSalesRep) {
        _currentSalesRepId = authState.user.id;
        fetchMyAgents();
      } else if (authState is AuthUnauthenticated) {
        _currentSalesRepId = '';
        emit(const SalesRepState());
      }
    });

    final initialAuthState = _authBloc.state;
    if (initialAuthState is AuthAuthenticated && initialAuthState.user.isSalesRep) {
      _currentSalesRepId = initialAuthState.user.id;
      fetchMyAgents();
    }
  }

  Future<void> fetchMyAgents() async {
    if (_currentSalesRepId.isEmpty) return;
    if (state.status != SalesRepStatus.success) {
      emit(state.copyWith(status: SalesRepStatus.loading));
    }
    final result = await _adminRepository.getAgentsBySalesRepId(_currentSalesRepId);
    result.fold(
          (failure) => emit(state.copyWith(status: SalesRepStatus.error, errorMessage: failure.message)),
          (agents) => emit(state.copyWith(status: SalesRepStatus.success, myAgents: agents)),
    );
  }

  Future<void> updateAgentDebt({
    required String agentId,
    required double newDebtAmount,
  }) async {
    // Kiểm tra để chắc chắn rằng NVKD đã đăng nhập
    if (_currentSalesRepId.isEmpty) {
      emit(state.copyWith(
        status: SalesRepStatus.error,
        errorMessage: 'Lỗi xác thực người dùng.',
      ));
      return;
    }

    final result = await _adminRepository.updateUserDebt(
      userId: agentId,
      newDebtAmount: newDebtAmount,
      updatedBy: _currentSalesRepId, // Truyền ID của NVKD hiện tại
    );

    result.fold(
          (failure) {
        emit(state.copyWith(
          status: SalesRepStatus.error,
          errorMessage: 'Cập nhật công nợ thất bại: ${failure.message}',
        ));
        emit(state.copyWith(status: SalesRepStatus.success));
      },
          (_) => fetchMyAgents(),
    );
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}