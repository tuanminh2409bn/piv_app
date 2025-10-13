part of 'admin_vouchers_cubit.dart';

enum AdminVoucherStatus { initial, loading, success, error }

class AdminVouchersState extends Equatable {
  final AdminVoucherStatus status;
  // Dùng model mới để chứa cả tên người tạo
  final List<VoucherWithDetails> pendingCreationVouchers;
  final List<VoucherWithDetails> pendingDeletionVouchers;
  final String? errorMessage;

  const AdminVouchersState({
    this.status = AdminVoucherStatus.initial,
    this.pendingCreationVouchers = const [],
    this.pendingDeletionVouchers = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, pendingCreationVouchers, pendingDeletionVouchers, errorMessage];

  AdminVouchersState copyWith({
    AdminVoucherStatus? status,
    List<VoucherWithDetails>? pendingCreationVouchers,
    List<VoucherWithDetails>? pendingDeletionVouchers,
    String? errorMessage,
  }) {
    return AdminVouchersState(
      status: status ?? this.status,
      pendingCreationVouchers: pendingCreationVouchers ?? this.pendingCreationVouchers,
      pendingDeletionVouchers: pendingDeletionVouchers ?? this.pendingDeletionVouchers,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}