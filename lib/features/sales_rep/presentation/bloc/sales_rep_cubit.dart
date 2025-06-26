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
        // Tải cả hai danh sách khi đăng nhập
        fetchMyAgents();
        fetchPendingAgents();
      } else if (authState is AuthUnauthenticated) {
        _currentSalesRepId = '';
        emit(const SalesRepState()); // Reset state khi đăng xuất
      }
    });

    final initialAuthState = _authBloc.state;
    if (initialAuthState is AuthAuthenticated && initialAuthState.user.isSalesRep) {
      _currentSalesRepId = initialAuthState.user.id;
      fetchMyAgents();
      fetchPendingAgents();
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

  Future<void> fetchPendingAgents() async {
    if (_currentSalesRepId.isEmpty) return;
    emit(state.copyWith(status: SalesRepStatus.loading));
    final result = await _adminRepository.getPendingAgentsBySalesRepId(_currentSalesRepId);
    result.fold(
          (failure) => emit(state.copyWith(status: SalesRepStatus.error, errorMessage: failure.message)),
          (agents) => emit(state.copyWith(status: SalesRepStatus.success, pendingAgents: agents)),
    );
  }

  Future<void> approveAgent(String agentId, String role) async {
    // Đảm bảo NVKD không thể gán quyền admin
    if (role == 'admin') {
      emit(state.copyWith(status: SalesRepStatus.error, errorMessage: "Bạn không có quyền gán vai trò Quản trị viên."));
      return;
    }

    emit(state.copyWith(status: SalesRepStatus.loading));
    final result = await _adminRepository.updateUser(agentId, role, 'active');
    result.fold(
          (failure) => emit(state.copyWith(status: SalesRepStatus.error, errorMessage: failure.message)),
          (_) {
        // Sau khi phê duyệt thành công, tải lại cả hai danh sách để cập nhật giao diện
        fetchMyAgents();
        fetchPendingAgents();
      },
    );
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}