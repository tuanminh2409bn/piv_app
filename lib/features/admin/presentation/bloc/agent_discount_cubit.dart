import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/data/models/discount_policy_model.dart';
import 'package:piv_app/features/admin/data/models/discount_request_model.dart';
import 'package:piv_app/features/admin/domain/repositories/discount_repository.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';

part 'agent_discount_state.dart';

class AgentDiscountCubit extends Cubit<AgentDiscountState> {
  final DiscountRepository _repository;
  final AuthBloc _authBloc;
  final String _agentId;
  StreamSubscription? _subscription;

  AgentDiscountCubit({
    required DiscountRepository repository,
    required AuthBloc authBloc,
    required String agentId,
  })  : _repository = repository,
        _authBloc = authBloc,
        _agentId = agentId,
        super(const AgentDiscountState());

  void init() {
    _watchPendingRequest();
  }

  void _watchPendingRequest() {
    _subscription?.cancel();
    _subscription = _repository.watchPendingRequestForAgent(_agentId).listen((request) {
      if (!isClosed) {
        emit(state.copyWith(pendingRequest: request));
      }
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  Future<void> saveConfig({
    required UserModel agent,
    required bool enabled,
    required AgentPolicy policy,
  }) async {
    emit(state.copyWith(status: AgentDiscountStatus.loading));

    final authState = _authBloc.state;
    if (authState is! AuthAuthenticated) {
      emit(state.copyWith(status: AgentDiscountStatus.error, errorMessage: "Lỗi xác thực."));
      return;
    }

    final currentUser = authState.user;
    final isAuthorizedAdmin = currentUser.role == 'admin';

    try {
      if (isAuthorizedAdmin) {
        // Admin cập nhật trực tiếp
        await _repository.updateDirectly(
          userId: agent.id,
          enabled: enabled,
          policy: policy,
        );
        emit(state.copyWith(status: AgentDiscountStatus.success, successMessage: "Đã cập nhật cấu hình thành công."));
      } else {
        // NVKD/Kế toán gửi yêu cầu
        final request = DiscountRequestModel(
          id: '', // Firestore sẽ tự sinh ID
          agentId: agent.id,
          agentName: agent.displayName ?? 'Đại lý',
          requesterId: currentUser.id,
          requesterName: currentUser.displayName ?? 'Nhân viên',
          requesterRole: currentUser.role,
          customDiscount: {
            'enabled': enabled,
            'policy': policy.toJson(),
          },
          status: 'pending',
          createdAt: Timestamp.now(),
        );
        await _repository.createRequest(request);
        emit(state.copyWith(status: AgentDiscountStatus.success, successMessage: "Đã gửi yêu cầu duyệt thành công."));
      }
    } catch (e) {
      emit(state.copyWith(status: AgentDiscountStatus.error, errorMessage: e.toString()));
    }
  }
}
