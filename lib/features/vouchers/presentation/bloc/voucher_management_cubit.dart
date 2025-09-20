import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';
import 'package:piv_app/features/vouchers/domain/repositories/voucher_repository.dart';

part 'voucher_management_state.dart';

class VoucherManagementCubit extends Cubit<VoucherManagementState> {
  final VoucherRepository _voucherRepository;
  final AuthBloc _authBloc;
  StreamSubscription? _vouchersSubscription;

  VoucherManagementCubit({
    required VoucherRepository voucherRepository,
    required AuthBloc authBloc,
  })  : _voucherRepository = voucherRepository,
        _authBloc = authBloc,
        super(const VoucherManagementState());

  void getVouchers() {
    final userState = _authBloc.state;
    if (userState is AuthAuthenticated) {
      final userId = userState.user.id;
      emit(state.copyWith(status: VoucherManagementStatus.loading));
      _vouchersSubscription?.cancel();
      _vouchersSubscription = _voucherRepository.getVouchersBySalesRep(userId).listen(
            (vouchers) {
          emit(state.copyWith(status: VoucherManagementStatus.success, vouchers: vouchers));
        },
        onError: (error) {
          emit(state.copyWith(status: VoucherManagementStatus.error, errorMessage: error.toString()));
        },
      );
    }
  }

  Future<void> saveVoucher({
    String? id,
    required String code,
    required String description,
    required DiscountType discountType,
    required double discountValue,
    required double minOrderValue,
    double? maxDiscountAmount,
    required int maxUses,
    required DateTime expiresAt,
  }) async {
    final userState = _authBloc.state;
    if (userState is! AuthAuthenticated) {
      emit(state.copyWith(status: VoucherManagementStatus.error, errorMessage: "Người dùng chưa xác thực."));
      return;
    }

    emit(state.copyWith(status: VoucherManagementStatus.loading));

    final voucher = VoucherModel(
      id: id ?? code.toUpperCase(),
      description: description,
      discountType: discountType,
      discountValue: discountValue,
      minOrderValue: minOrderValue,
      maxDiscountAmount: maxDiscountAmount,
      maxUses: maxUses,
      expiresAt: Timestamp.fromDate(expiresAt),
      createdAt: id != null ? state.vouchers.firstWhere((v) => v.id == id).createdAt : Timestamp.now(),
      createdBy: userState.user.id,
      status: VoucherStatus.pendingApproval,
      // Thêm lịch sử cho hành động
      history: [
        VoucherHistoryEntry(
          action: id == null ? 'created' : 'updated',
          actorId: userState.user.id,
          timestamp: Timestamp.now(),
        ),
      ],
    );

    final result = id == null
        ? await _voucherRepository.addVoucher(voucher)
        : await _voucherRepository.updateVoucher(voucher);

    result.fold(
          (failure) => emit(state.copyWith(status: VoucherManagementStatus.error, errorMessage: failure.message)),
          (_) => emit(state.copyWith(status: VoucherManagementStatus.success)), // Chỉ cần chuyển trạng thái, stream sẽ tự cập nhật list
    );
  }

  @override
  Future<void> close() {
    _vouchersSubscription?.cancel();
    return super.close();
  }
}