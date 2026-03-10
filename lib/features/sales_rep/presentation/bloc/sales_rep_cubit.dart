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
  StreamSubscription? _agentsSubscription;
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
        _watchMyAgents();
      } else if (authState is AuthUnauthenticated) {
        _currentSalesRepId = '';
        _agentsSubscription?.cancel();
        emit(const SalesRepState());
      }
    });

    final initialAuthState = _authBloc.state;
    if (initialAuthState is AuthAuthenticated && initialAuthState.user.isSalesRep) {
      _currentSalesRepId = initialAuthState.user.id;
      _watchMyAgents();
    }
  }

  void _watchMyAgents() {
    if (_currentSalesRepId.isEmpty) return;
    emit(state.copyWith(status: SalesRepStatus.loading));
    _agentsSubscription?.cancel();
    _agentsSubscription = _adminRepository.watchAgentsBySalesRepId(_currentSalesRepId).listen(
      (agents) {
        final activeAgents = agents.where((a) => a.status == 'active').toList();
        emit(state.copyWith(status: SalesRepStatus.success, myAgents: activeAgents));
      },
      onError: (error) {
        emit(state.copyWith(status: SalesRepStatus.error, errorMessage: error.toString()));
      },
    );
  }

  Future<void> fetchMyAgents() async {
    // Không cần làm gì vì _watchMyAgents đã xử lý
  }

  Future<void> updateAgentDebt({
    required String agentId,
    required double newDebtAmount,
  }) async {
    // Lấy thông tin người dùng đang đăng nhập
    final authState = _authBloc.state;
    if (authState is! AuthAuthenticated) {
      emit(state.copyWith(
        status: SalesRepStatus.error,
        errorMessage: 'Lỗi xác thực người dùng.',
      ));
      return;
    }

    final currentUser = authState.user;
    emit(state.copyWith(status: SalesRepStatus.loading));

    if (currentUser.isAdmin) {
      // Admin cập nhật trực tiếp
      final result = await _adminRepository.updateUserDebt(
        userId: agentId,
        newDebtAmount: newDebtAmount,
        updatedBy: currentUser.id,
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
    } else {
      // Sales Rep / Accountant gửi yêu cầu phê duyệt
      final targetUser = state.myAgents.firstWhere(
        (u) => u.id == agentId,
        orElse: () => UserModel.empty,
      );

      if (targetUser.isEmpty) {
        emit(state.copyWith(
          status: SalesRepStatus.error,
          errorMessage: 'Không tìm thấy thông tin đại lý.',
        ));
        emit(state.copyWith(status: SalesRepStatus.success));
        return;
      }

      final result = await _adminRepository.createDebtUpdateRequest(
        userId: agentId,
        userName: targetUser.displayName ?? targetUser.email ?? 'Ẩn danh',
        oldDebtAmount: targetUser.debtAmount,
        newDebtAmount: newDebtAmount,
        requestedBy: currentUser.id,
        requestedByName: currentUser.displayName ?? currentUser.email ?? 'Nhân viên',
      );

      result.fold(
            (failure) {
          emit(state.copyWith(
            status: SalesRepStatus.error,
            errorMessage: 'Gửi yêu cầu thất bại: ${failure.message}',
          ));
          emit(state.copyWith(status: SalesRepStatus.success));
        },
            (_) {
          emit(state.copyWith(
            status: SalesRepStatus.success,
            errorMessage: 'Yêu cầu cập nhật công nợ đã được gửi tới Admin phê duyệt.',
          ));
          // Sau khi gửi yêu cầu, cập nhật lại trạng thái thành công để tắt loading
          emit(state.copyWith(status: SalesRepStatus.success));
        },
      );
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _agentsSubscription?.cancel();
    return super.close();
  }
}
