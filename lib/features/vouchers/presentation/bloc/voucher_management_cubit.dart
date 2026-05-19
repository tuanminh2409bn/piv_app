// lib/features/vouchers/presentation/bloc/voucher_management_cubit.dart

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
      final isAdmin = userState.user.isAdmin;
      emit(state.copyWith(status: VoucherManagementStatus.loading));
      _vouchersSubscription?.cancel();
      
      final stream = isAdmin 
          ? _voucherRepository.getAllVouchers() 
          : _voucherRepository.getVouchersBySalesRep(userId);

      _vouchersSubscription = stream.listen(
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
    int? minQuantity, // MỚI
    int? maxQuantity, // MỚI
    double? maxDiscountAmount,
    required int maxUses,
    required DateTime expiresAt,
    int? buyQuantity,
    int? getQuantity,
    String targetType = 'all',
    List<String> targetUserIds = const [],
    List<String> targetSalesRepIds = const [],
    List<String> excludedUserIds = const [], // MỚI
    List<String> excludedSalesRepIds = const [], // MỚI
    String applicableCategory = 'all',
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
      minQuantity: minQuantity, // MỚI
      maxQuantity: maxQuantity, // MỚI
      maxDiscountAmount: maxDiscountAmount,
      maxUses: maxUses,
      expiresAt: Timestamp.fromDate(expiresAt),
      createdAt: originalVoucher?.createdAt ?? Timestamp.now(), 
      createdBy: originalVoucher?.createdBy ?? userState.user.id, 
      status: originalVoucher?.status ?? (userState.user.isAdmin ? VoucherStatus.active : VoucherStatus.pendingApproval),
      history: originalVoucher?.history ?? [],
      approvedBy: originalVoucher?.approvedBy,
      buyQuantity: buyQuantity,
      getQuantity: getQuantity,
      targetType: targetType,
      targetUserIds: targetUserIds,
      targetSalesRepIds: targetSalesRepIds,
      excludedUserIds: excludedUserIds, // MỚI
      excludedSalesRepIds: excludedSalesRepIds, // MỚI
      applicableCategory: applicableCategory,
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
      status: userState.user.isAdmin ? VoucherStatus.active : VoucherStatus.pendingApproval, 
      history: (originalVoucher?.history ?? []) + [newHistoryEntry],
      approvedBy: userState.user.isAdmin ? userState.user.id : originalVoucher?.approvedBy,
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

    if (userState.user.isAdmin) {
      // Nếu là Admin thì xóa ngay lập tức
      final result = await _voucherRepository.deleteVoucher(voucher.id);
      result.fold(
            (failure) => emit(state.copyWith(status: VoucherManagementStatus.error, errorMessage: failure.message)),
            (_) => emit(state.copyWith(status: VoucherManagementStatus.success)),
      );
      return;
    }

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
