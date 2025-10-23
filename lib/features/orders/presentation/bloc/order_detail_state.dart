// lib/features/orders/presentation/bloc/order_detail_state.dart

part of 'order_detail_cubit.dart';

enum OrderDetailStatus {
  initial,
  loading,
  success,
  error,
  updating, // Trạng thái chung khi duyệt/từ chối
  updatingPaymentStatus, // Trạng thái khi xác nhận thanh toán
  // +++ THÊM TRẠNG THÁI VOUCHER +++
  applyingVoucher,
  voucherError,
  // +++ KẾT THÚC THÊM +++
}

class OrderDetailState extends Equatable {
  final OrderDetailStatus status;
  final OrderModel? order;
  final String? errorMessage;
  final PaymentInfoModel? paymentInfo;
  final UserModel? placedByUser;
  final ReturnRequestModel? returnRequest;
  // +++ THÊM TRƯỜNG VOUCHER +++
  final VoucherModel? appliedVoucher;
  final double voucherDiscount; // Lưu số tiền giảm giá từ voucher
  // +++ KẾT THÚC THÊM +++

  const OrderDetailState({
    this.status = OrderDetailStatus.initial,
    this.order,
    this.errorMessage,
    this.paymentInfo,
    this.placedByUser,
    this.returnRequest,
    // +++ KHỞI TẠO VOUCHER +++
    this.appliedVoucher,
    this.voucherDiscount = 0.0,
    // +++ KẾT THÚC KHỞI TẠO +++
  });

  @override
  List<Object?> get props => [
    status,
    order,
    errorMessage,
    paymentInfo,
    placedByUser,
    returnRequest,
    // +++ THÊM PROPS VOUCHER +++
    appliedVoucher,
    voucherDiscount,
    // +++ KẾT THÚC THÊM +++
  ];

  OrderDetailState copyWith({
    OrderDetailStatus? status,
    OrderModel? order,
    String? errorMessage,
    PaymentInfoModel? paymentInfo,
    UserModel? placedByUser,
    ReturnRequestModel? returnRequest,
    bool clearError = false,
    // +++ THÊM THAM SỐ VOUCHER +++
    VoucherModel? appliedVoucher,
    bool forceVoucherToNull = false, // Để xóa voucher
    double? voucherDiscount,
    // +++ KẾT THÚC THÊM +++
  }) {
    return OrderDetailState(
      status: status ?? this.status,
      order: order ?? this.order,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      paymentInfo: paymentInfo ?? this.paymentInfo,
      placedByUser: placedByUser ?? this.placedByUser,
      returnRequest: returnRequest ?? this.returnRequest,
      // +++ CẬP NHẬT VOUCHER +++
      // Nếu forceVoucherToNull là true, đặt voucher và discount về null/0
      appliedVoucher: forceVoucherToNull ? null : (appliedVoucher ?? this.appliedVoucher),
      voucherDiscount: forceVoucherToNull ? 0.0 : (voucherDiscount ?? this.voucherDiscount),
      // +++ KẾT THÚC CẬP NHẬT +++
    );
  }
}