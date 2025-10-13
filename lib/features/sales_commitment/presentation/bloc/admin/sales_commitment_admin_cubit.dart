// lib/features/sales_commitment/presentation/bloc/admin/sales_commitment_admin_cubit.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/sales_commitment_model.dart';
import 'package:piv_app/features/sales_commitment/domain/repositories/sales_commitment_repository.dart';

part 'sales_commitment_admin_state.dart';

class SalesCommitmentAdminCubit extends Cubit<SalesCommitmentAdminState> {
  final SalesCommitmentRepository _repository;
  StreamSubscription? _commitmentsSubscription;

  SalesCommitmentAdminCubit({required SalesCommitmentRepository repository})
      : _repository = repository,
        super(const SalesCommitmentAdminState());

  void watchAllCommitments() {
    _commitmentsSubscription?.cancel();
    emit(state.copyWith(status: SalesCommitmentAdminStatus.loading));
    _commitmentsSubscription = _repository.watchAllCommitments().listen(
          (commitments) {
        emit(state.copyWith(
          status: SalesCommitmentAdminStatus.success,
          commitments: commitments,
        ));
      },
      onError: (error) {
        emit(state.copyWith(
          status: SalesCommitmentAdminStatus.error,
          errorMessage: 'Lỗi tải danh sách cam kết.',
        ));
      },
    );
  }

  Future<void> setCommitmentDetails({
    required String commitmentId,
    required String detailsText,
  }) async {
    final result = await _repository.setSalesCommitmentDetails(
      commitmentId: commitmentId,
      detailsText: detailsText,
    );
    // Không cần emit state vì danh sách sẽ tự cập nhật qua stream,
    // nhưng có thể emit lỗi để hiển thị snackbar nếu cần.
    result.fold(
          (failure) => emit(state.copyWith(
        status: SalesCommitmentAdminStatus.error,
        errorMessage: failure.message,
      )),
          (_) {
        // Có thể emit một state thành công riêng nếu muốn hiển thị thông báo
      },
    );
  }

  @override
  Future<void> close() {
    _commitmentsSubscription?.cancel();
    return super.close();
  }
}