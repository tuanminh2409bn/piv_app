part of 'voucher_management_cubit.dart';

enum VoucherManagementStatus { initial, loading, success, error }

class VoucherManagementState extends Equatable {
  final VoucherManagementStatus status;
  final List<VoucherModel> vouchers;
  final String? errorMessage;

  const VoucherManagementState({
    this.status = VoucherManagementStatus.initial,
    this.vouchers = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, vouchers, errorMessage];

  VoucherManagementState copyWith({
    VoucherManagementStatus? status,
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