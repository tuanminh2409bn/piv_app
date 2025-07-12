import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/user_model.dart';
// Đảm bảo import đúng Auth Repo của bạn, ví dụ:
import 'package:piv_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';

part 'agent_approval_state.dart';

class AgentApprovalCubit extends Cubit<AgentApprovalState> {
  final UserProfileRepository _userProfileRepository;
  final AuthRepository _authRepository;

  AgentApprovalCubit({
    required UserProfileRepository userProfileRepository,
    required AuthRepository authRepository,
  })  : _userProfileRepository = userProfileRepository,
        _authRepository = authRepository,
        super(AgentApprovalInitial());

  Future<void> fetchUnassignedAgents() async {
    emit(AgentApprovalLoading());
    final result = await _userProfileRepository.getUnassignedAgents();

    result.fold(
          (failure) => emit(AgentApprovalFailure(failure.message)),
          (users) => emit(AgentApprovalLoaded(users)),
    );
  }

  Future<void> approveAgent(String agentId) async {
    // ‼️ SỬA LỖI TẠI ĐÂY
    // Lấy thông tin NVKD hiện tại.
    // Vì authRepository trả về `Future`, chúng ta cần `await` nó.
    final Either<Failure, UserModel> authResult = await _authRepository.getCurrentUser();

    // Dùng `fold` để xử lý kết quả an toàn
    authResult.fold(
          (failure) {
        // Nếu có lỗi khi lấy thông tin NVKD, phát ra state lỗi
        emit(AgentApprovalFailure('Lỗi xác thực NVKD: ${failure.message}'));
      },
          (salesRepUser) async {
        // Nếu lấy thông tin NVKD thành công, tiến hành duyệt đại lý
        final approvalResult = await _userProfileRepository.assignAgentToSalesRep(
          agentId: agentId,
          salesRepId: salesRepUser.id, // Sử dụng 'id' từ UserModel
        );

        approvalResult.fold(
              (failure) => emit(AgentApprovalFailure('Lỗi khi duyệt đại lý: ${failure.message}')),
              (_) => fetchUnassignedAgents(), // Duyệt thành công, tải lại danh sách
        );
      },
    );
  }
}