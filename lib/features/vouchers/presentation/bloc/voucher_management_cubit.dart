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

  VoucherManagementCubit({
    required VoucherRepository voucherRepository,
    required AuthBloc authBloc,
  })  : _voucherRepository = voucherRepository,
        _authBloc = authBloc,
        super(const VoucherManagementState());

  String get _salesRepId {
    final authState = _authBloc.state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return '';
  }

  Future<void> loadVouchers() async {
    final salesRepId = _salesRepId;
    if (salesRepId.isEmpty) return;

    emit(state.copyWith(status: VoucherStatus.loading));
    final result = await _voucherRepository.getVouchersBySalesRep(salesRepId);
    result.fold(
          (failure) => emit(state.copyWith(status: VoucherStatus.error, errorMessage: failure.message)),
          (vouchers) => emit(state.copyWith(status: VoucherStatus.success, vouchers: vouchers)),
    );
  }

  Future<void> createVoucher({
    required String code,
    required String description,
    required DiscountType discountType,
    required double discountValue,
    required DateTime expiresAt,
    required int maxUses,
  }) async {
    final salesRepId = _salesRepId;
    if (salesRepId.isEmpty) {
      emit(state.copyWith(status: VoucherStatus.error, errorMessage: "Không thể xác thực người dùng."));
      return;
    }

    emit(state.copyWith(status: VoucherStatus.submitting));

    final newVoucher = VoucherModel(
      id: code.toUpperCase(), // Luôn lưu mã dạng chữ hoa
      description: description,
      discountType: discountType,
      discountValue: discountValue,
      salesRepId: salesRepId,
      createdAt: Timestamp.now(),
      expiresAt: Timestamp.fromDate(expiresAt),
      maxUses: maxUses,
      isActive: true,
      usesCount: 0,
    );

    final result = await _voucherRepository.createVoucher(newVoucher);
    result.fold(
          (failure) => emit(state.copyWith(status: VoucherStatus.error, errorMessage: failure.message)),
          (_) {
        // Sau khi tạo thành công, tải lại danh sách
        loadVouchers();
      },
    );
  }
}