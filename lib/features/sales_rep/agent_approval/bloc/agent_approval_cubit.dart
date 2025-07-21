// lib/features/sales_rep/agent_approval/bloc/agent_approval_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';

part 'agent_approval_state.dart';

class AgentApprovalCubit extends Cubit<AgentApprovalState> {
  final UserProfileRepository _userProfileRepository;

  AgentApprovalCubit({
    required UserProfileRepository userProfileRepository,
  })  : _userProfileRepository = userProfileRepository,
        super(AgentApprovalInitial());

  Future<void> fetchUnassignedAgents() async {
    emit(AgentApprovalLoading());
    final result = await _userProfileRepository.getUnassignedAgents();

    result.fold(
          (failure) => emit(AgentApprovalFailure(failure.message)),
          (users) => emit(AgentApprovalLoaded(users)),
    );
  }

  // SỬA: Thay thế hoàn toàn hàm approveAgent cũ bằng hàm mới
  Future<void> approveAgent(String agentId, String roleToSet) async {
    // Không cần emit loading ở đây để UI mượt hơn
    final result = await _userProfileRepository.approveAgentWithRole(
      agentId: agentId,
      roleToSet: roleToSet,
    );

    result.fold(
          (failure) => emit(AgentApprovalFailure(failure.message)),
          (_) {
        emit(AgentApprovalSuccess()); // Báo hiệu thành công
        fetchUnassignedAgents(); // Tải lại danh sách chờ
      },
    );
  }
}