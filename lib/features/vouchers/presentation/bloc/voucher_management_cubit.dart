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
  }) async {
    final userState = _authBloc.state;
    if (userState is! AuthAuthenticated) {
      emit(state.copyWith(status: VoucherManagementStatus.error, errorMessage: "Người dùng chưa xác thực."));
      return;
    }

    emit(state.copyWith(status: VoucherManagementStatus.loading));

    // --- SỬA LỖI LOGIC BẮT ĐẦU TỪ ĐÂY ---

    // 1. Lấy thông tin voucher gốc nếu là chỉnh sửa
    VoucherModel? originalVoucher;
    if (id != null) {
      try {
        originalVoucher = state.vouchers.firstWhere((v) => v.id == id);
      } catch (e) {
        emit(state.copyWith(status: VoucherManagementStatus.error, errorMessage: "Không tìm thấy voucher gốc."));
        return;
      }
    }

    // 2. Xây dựng model voucher mới dựa trên form
    final newVoucherData = VoucherModel(
      id: id ?? code.toUpperCase(),
      description: description,
      discountType: discountType,
      discountValue: discountValue,
      minOrderValue: minOrderValue,
      maxDiscountAmount: maxDiscountAmount,
      maxUses: maxUses,
      expiresAt: Timestamp.fromDate(expiresAt),
      createdAt: originalVoucher?.createdAt ?? Timestamp.now(), // Giữ ngày tạo gốc
      createdBy: originalVoucher?.createdBy ?? userState.user.id, // Giữ người tạo gốc
      status: originalVoucher?.status ?? VoucherStatus.pendingApproval, // Tạm thời giữ status cũ
      history: originalVoucher?.history ?? [], // Tạm thời giữ history cũ
      approvedBy: originalVoucher?.approvedBy,
    );

    // 3. So sánh xem có thay đổi gì không
    bool hasChanges = true;
    if (originalVoucher != null) {
      // So sánh 2 bản "sạch" (không tính status và history)
      final comparableOriginal = originalVoucher.copyWith(status: '', history: []);
      final comparableNew = newVoucherData.copyWith(status: '', history: []);

      // <<< THÊM LOG DEBUG Ở ĐÂY >>>
      developer.log("Comparing vouchers:", name: "VoucherCubit");
      developer.log("Original (comparable): ${comparableOriginal.toString()}", name: "VoucherCubit");
      developer.log("New data (comparable): ${comparableNew.toString()}", name: "VoucherCubit");
      developer.log("Are they equal? ${comparableOriginal == comparableNew}", name: "VoucherCubit");
      // <<< KẾT THÚC LOG DEBUG >>>

      if (comparableOriginal == comparableNew) {
        hasChanges = false;
      }
    }

    // 4. Xử lý logic
    // Nếu không có thay đổi (NVKD chỉ nhấn "Lưu" mà không sửa gì)
    if (id != null && !hasChanges) {
      // <<< THÊM LOG DEBUG Ở ĐÂY >>>
      developer.log("Voucher save skipped: No changes detected.", name: "VoucherCubit");
      emit(state.copyWith(status: VoucherManagementStatus.success)); // Chỉ cần quay lại
      return;
    } else {
      // <<< THÊM LOG DEBUG Ở ĐÂY >>>
      developer.log("Voucher save proceeding: Changes detected or new voucher.", name: "VoucherCubit");
    }

    // Nếu CÓ THAY ĐỔI (hoặc là TẠO MỚI)
    // -> Luôn đặt status là 'pending_approval' và thêm lịch sử
    final newHistoryEntry = VoucherHistoryEntry(
      action: id == null ? 'created' : 'updated',
      actorId: userState.user.id,
      timestamp: Timestamp.now(),
    );

    final finalVoucher = newVoucherData.copyWith(
      status: VoucherStatus.pendingApproval, // Bắt buộc duyệt lại
      history: (originalVoucher?.history ?? []) + [newHistoryEntry],
    );
    // --- KẾT THÚC SỬA LỖI LOGIC ---

    final result = id == null
        ? await _voucherRepository.addVoucher(finalVoucher)
        : await _voucherRepository.updateVoucher(finalVoucher);

    result.fold(
          (failure) => emit(state.copyWith(status: VoucherManagementStatus.error, errorMessage: failure.message)),
          (_) => emit(state.copyWith(status: VoucherManagementStatus.success)),
    );
  }

  // --- THÊM HÀM MỚI ĐỂ YÊU CẦU XÓA ---
  Future<void> requestDeleteVoucher(VoucherModel voucher) async {
    final userState = _authBloc.state;
    if (userState is! AuthAuthenticated) {
      emit(state.copyWith(status: VoucherManagementStatus.error, errorMessage: "Người dùng chưa xác thực."));
      return;
    }

    // Không cho phép yêu cầu xóa voucher đang chờ xóa
    if (voucher.status == VoucherStatus.pendingDeletion) return;

    emit(state.copyWith(status: VoucherManagementStatus.loading));

    final newHistoryEntry = VoucherHistoryEntry(
      action: 'delete_requested', // Hành động mới
      actorId: userState.user.id,
      timestamp: Timestamp.now(),
    );

    final voucherToUpdate = voucher.copyWith(
      statusBeforeDeletion: voucher.status,
      status: VoucherStatus.pendingDeletion, // Chuyển sang chờ xóa
      history: voucher.history + [newHistoryEntry],
    );

    final result = await _voucherRepository.updateVoucher(voucherToUpdate);

    result.fold(
          (failure) => emit(state.copyWith(status: VoucherManagementStatus.error, errorMessage: failure.message)),
          (_) => emit(state.copyWith(status: VoucherManagementStatus.success)),
    );
  }
  // --- KẾT THÚC HÀM MỚI ---

  @override
  Future<void> close() {
    _vouchersSubscription?.cancel();
    return super.close();
  }
}