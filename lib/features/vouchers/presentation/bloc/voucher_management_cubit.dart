// lib/features/vouchers/presentation/bloc/voucher_management_cubit.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';
import 'package:piv_app/features/vouchers/domain/repositories/voucher_repository.dart';
import 'dart:developer' as developer;

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
    int? buyQuantity,
    int? getQuantity,
  }) async {
    final userState = _authBloc.state;
    if (userState is! AuthAuthenticated) {
      emit(state.copyWith(status: VoucherManagementStatus.error, errorMessage: "Người dùng chưa xác thực."));
      return;
    }

    emit(state.copyWith(status: VoucherManagementStatus.loading));

    VoucherModel? originalVoucher;
    if (id != null) {
      try {
        originalVoucher = state.vouchers.firstWhere((v) => v.id == id);
      } catch (e) {
        emit(state.copyWith(status: VoucherManagementStatus.error, errorMessage: "Không tìm thấy voucher gốc."));
        return;
      }
    }

    final newVoucherData = VoucherModel(
      id: id ?? code.toUpperCase(),
      description: description,
      discountType: discountType,
      discountValue: discountValue,
      minOrderValue: minOrderValue,
      maxDiscountAmount: maxDiscountAmount,
      maxUses: maxUses,
      expiresAt: Timestamp.fromDate(expiresAt),
      createdAt: originalVoucher?.createdAt ?? Timestamp.now(), 
      createdBy: originalVoucher?.createdBy ?? userState.user.id, 
      status: originalVoucher?.status ?? VoucherStatus.pendingApproval, 
      history: originalVoucher?.history ?? [], 
      approvedBy: originalVoucher?.approvedBy,
      buyQuantity: buyQuantity,
      getQuantity: getQuantity,
    );

    bool hasChanges = true;
    if (originalVoucher != null) {
      final comparableOriginal = originalVoucher.copyWith(status: '', history: []);
      final comparableNew = newVoucherData.copyWith(status: '', history: []);

      if (comparableOriginal == comparableNew) {
        hasChanges = false;
      }
    }

    if (id != null && !hasChanges) {
      emit(state.copyWith(status: VoucherManagementStatus.success)); 
      return;
    } 

    final newHistoryEntry = VoucherHistoryEntry(
      action: id == null ? 'created' : 'updated',
      actorId: userState.user.id,
      timestamp: Timestamp.now(),
    );

    final finalVoucher = newVoucherData.copyWith(
      status: VoucherStatus.pendingApproval, 
      history: (originalVoucher?.history ?? []) + [newHistoryEntry],
    );

    final result = id == null
        ? await _voucherRepository.addVoucher(finalVoucher)
        : await _voucherRepository.updateVoucher(finalVoucher);

    result.fold(
          (failure) => emit(state.copyWith(status: VoucherManagementStatus.error, errorMessage: failure.message)),
          (_) => emit(state.copyWith(status: VoucherManagementStatus.success)),
    );
  }

  Future<void> requestDeleteVoucher(VoucherModel voucher) async {
    final userState = _authBloc.state;
    if (userState is! AuthAuthenticated) {
      emit(state.copyWith(status: VoucherManagementStatus.error, errorMessage: "Người dùng chưa xác thực."));
      return;
    }

    if (voucher.status == VoucherStatus.pendingDeletion) return;

    emit(state.copyWith(status: VoucherManagementStatus.loading));

    final newHistoryEntry = VoucherHistoryEntry(
      action: 'delete_requested',
      actorId: userState.user.id,
      timestamp: Timestamp.now(),
    );

    final voucherToUpdate = voucher.copyWith(
      statusBeforeDeletion: voucher.status,
      status: VoucherStatus.pendingDeletion,
      history: voucher.history + [newHistoryEntry],
    );

    final result = await _voucherRepository.updateVoucher(voucherToUpdate);

    result.fold(
          (failure) => emit(state.copyWith(status: VoucherManagementStatus.error, errorMessage: failure.message)),
          (_) => emit(state.copyWith(status: VoucherManagementStatus.success)),
    );
  }

  @override
  Future<void> close() {
    _vouchersSubscription?.cancel();
    return super.close();
  }
}
