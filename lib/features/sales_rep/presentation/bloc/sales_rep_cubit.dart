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
      if (authState is AuthAuthenticated && authState.user.role == 'sales_rep') {
        _currentSalesRepId = authState.user.id;
        fetchMyAgents();
      }
    });

    final initialAuthState = _authBloc.state;
    if (initialAuthState is AuthAuthenticated && initialAuthState.user.role == 'sales_rep') {
      _currentSalesRepId = initialAuthState.user.id;
      fetchMyAgents();
    }
  }

  Future<void> fetchMyAgents() async {
    if (_currentSalesRepId.isEmpty) return;

    emit(state.copyWith(status: SalesRepStatus.loading));
    final result = await _adminRepository.getAgentsBySalesRepId(_currentSalesRepId);
    result.fold(
          (failure) => emit(state.copyWith(status: SalesRepStatus.error, errorMessage: failure.message)),
          (agents) => emit(state.copyWith(status: SalesRepStatus.success, myAgents: agents)),
    );
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}