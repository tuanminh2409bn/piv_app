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

  SalesRepCubit({
    required AdminRepository adminRepository,
    required AuthBloc authBloc,
  })  : _adminRepository = adminRepository,
        _authBloc = authBloc,
  // --- Constructor giờ đây chỉ khởi tạo State ---
        super(const SalesRepState()) {
    // Việc lắng nghe stream vẫn có thể giữ lại
    _authSubscription = _authBloc.stream.listen((authState) {
      if (authState is AuthUnauthenticated) {
        // Nếu người dùng đăng xuất, xóa dữ liệu
        emit(const SalesRepState(status: SalesRepStatus.initial, myAgents: []));
      }
    });
  }
  // -------------------------------------------------

  Future<void> fetchMyAgents() async {
    final authState = _authBloc.state;
    if (authState is! AuthAuthenticated || authState.user.role != 'sales_rep') {
      return;
    }

    final salesRepId = authState.user.id;
    if (salesRepId.isEmpty) return;

    emit(state.copyWith(status: SalesRepStatus.loading));
    final result = await _adminRepository.getAgentsBySalesRepId(salesRepId);
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