// lib/features/orders/presentation/bloc/order_detail_state.dart

part of 'order_detail_cubit.dart';

// --- THAY ĐỔI: Xóa các trạng thái VNPAY, thêm trạng thái cập nhật thanh toán ---
enum OrderDetailStatus {
  initial,
  loading,
  success,
  error,
  updating, // Dùng cho Phê duyệt/Từ chối
  updatingPaymentStatus // Dùng cho nút "Tôi đã chuyển khoản"
}

class OrderDetailState extends Equatable {
  final OrderDetailStatus status;
  final OrderModel? order;
  final String? errorMessage;
  final PaymentInfoModel? paymentInfo;

  const OrderDetailState({
    this.status = OrderDetailStatus.initial,
    this.order,
    this.errorMessage,
    this.paymentInfo, // Thêm vào constructor
  });

  @override
  List<Object?> get props => [status, order, errorMessage, paymentInfo];

  OrderDetailState copyWith({
    OrderDetailStatus? status,
    OrderModel? order,
    String? errorMessage,
    PaymentInfoModel? paymentInfo,
    bool clearError = false,
  }) {
    return OrderDetailState(
      status: status ?? this.status,
      order: order ?? this.order,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      paymentInfo: paymentInfo ?? this.paymentInfo,
    );
  }
}