//lib/features/returns/presentation/bloc/admin_returns_cubit.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/returns/data/models/return_request_model.dart';
import 'package:piv_app/features/returns/domain/repositories/return_repository.dart';

part 'admin_returns_state.dart';

class AdminReturnsCubit extends Cubit<AdminReturnsState> {
  final ReturnRepository _returnRepository;
  StreamSubscription? _requestsSubscription;

  AdminReturnsCubit({required ReturnRepository returnRepository})
      : _returnRepository = returnRepository,
        super(const AdminReturnsState());

  void watchAllRequests() {
    emit(state.copyWith(status: AdminReturnsStatus.loading));
    _requestsSubscription?.cancel();
    _requestsSubscription = _returnRepository.watchAllReturnRequests().listen(
          (requests) {
        emit(state.copyWith(status: AdminReturnsStatus.success, allRequests: requests));
      },
      onError: (error) {
        emit(state.copyWith(status: AdminReturnsStatus.error, errorMessage: 'Không thể tải danh sách yêu cầu.'));
      },
    );
  }

  Future<void> updateRequestStatus({
    required String requestId,
    required String newStatus,
    String? adminNotes,
    String? rejectionReason, // <<< THÊM MỚI
  }) async {
    final result = await _returnRepository.updateReturnRequestStatus(
      requestId: requestId,
      newStatus: newStatus,
      adminNotes: adminNotes,
      rejectionReason: rejectionReason, // <<< THÊM MỚI
    );
    // UI sẽ tự cập nhật nhờ stream, không cần emit state ở đây
  }

  @override
  Future<void> close() {
    _requestsSubscription?.cancel();
    return super.close();
  }
}