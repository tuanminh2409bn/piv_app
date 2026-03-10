import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/admin/data/models/debt_update_request_model.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_repository.dart';
import 'dart:async';

part 'debt_approval_state.dart';

class DebtApprovalCubit extends Cubit<DebtApprovalState> {
  final AdminRepository _adminRepository;
  StreamSubscription? _requestsSubscription;

  DebtApprovalCubit({required AdminRepository adminRepository})
      : _adminRepository = adminRepository,
        super(const DebtApprovalState());

  void watchPendingRequests() {
    emit(state.copyWith(status: DebtApprovalStatus.loading));
    _requestsSubscription?.cancel();
    _requestsSubscription = _adminRepository.getPendingDebtUpdateRequests().listen(
      (requests) {
        emit(state.copyWith(
          status: DebtApprovalStatus.success,
          pendingRequests: requests,
        ));
      },
      onError: (error) {
        emit(state.copyWith(
          status: DebtApprovalStatus.error,
          errorMessage: error.toString(),
        ));
      },
    );
  }

  Future<void> approveRequest(String requestId, String adminId) async {
    emit(state.copyWith(status: DebtApprovalStatus.submitting));
    final result = await _adminRepository.approveDebtUpdateRequest(
      requestId: requestId,
      adminId: adminId,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: DebtApprovalStatus.error,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(status: DebtApprovalStatus.success)),
    );
  }

  Future<void> rejectRequest(String requestId, String adminId, String reason) async {
    emit(state.copyWith(status: DebtApprovalStatus.submitting));
    final result = await _adminRepository.rejectDebtUpdateRequest(
      requestId: requestId,
      adminId: adminId,
      reason: reason,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: DebtApprovalStatus.error,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(status: DebtApprovalStatus.success)),
    );
  }

  @override
  Future<void> close() {
    _requestsSubscription?.cancel();
    return super.close();
  }
}
