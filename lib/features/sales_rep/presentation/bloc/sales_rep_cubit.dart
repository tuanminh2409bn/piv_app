// lib/features/sales_rep/presentation/bloc/sales_rep_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/user_model.dart';
// Giữ nguyên dependency vào AdminRepository vì nó có hàm getAgentsBySalesRepId
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
        // Chỉ tải danh sách đại lý của tôi
        fetchMyAgents();
      } else if (authState is AuthUnauthenticated) {
        _currentSalesRepId = '';
        emit(const SalesRepState()); // Reset state khi đăng xuất
      }
    });

    // Xử lý trạng thái ban đầu khi Cubit được tạo
    final initialAuthState = _authBloc.state;
    if (initialAuthState is AuthAuthenticated && initialAuthState.user.isSalesRep) {
      _currentSalesRepId = initialAuthState.user.id;
      fetchMyAgents();
    }
  }

  /// Lấy danh sách các đại lý đang được quản lý bởi NVKD hiện tại.
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