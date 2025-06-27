part of 'voucher_management_cubit.dart';

enum VoucherStatus { initial, loading, success, error, submitting }

class VoucherManagementState extends Equatable {
  final VoucherStatus status;
  final List<VoucherModel> vouchers;
  final String? errorMessage;

  const VoucherManagementState({
    this.status = VoucherStatus.initial,
    this.vouchers = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, vouchers, errorMessage];

  VoucherManagementState copyWith({
    VoucherStatus? status,
    List<VoucherModel>? vouchers,
    String? errorMessage,
  }) {
    return VoucherManagementState(
      status: status ?? this.status,
      vouchers: vouchers ?? this.vouchers,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}