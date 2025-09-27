// lib/features/orders/presentation/bloc/order_detail_state.dart

part of 'order_detail_cubit.dart';

enum OrderDetailStatus {
  initial,
  loading,
  success,
  error,
  updating,
  updatingPaymentStatus
}

class OrderDetailState extends Equatable {
  final OrderDetailStatus status;
  final OrderModel? order;
  final String? errorMessage;
  final PaymentInfoModel? paymentInfo;
  final UserModel? placedByUser;
  final ReturnRequestModel? returnRequest;

  const OrderDetailState({
    this.status = OrderDetailStatus.initial,
    this.order,
    this.errorMessage,
    this.paymentInfo,
    this.placedByUser,
    this.returnRequest,
  });

  @override
  List<Object?> get props => [status, order, errorMessage, paymentInfo, placedByUser, returnRequest];

  OrderDetailState copyWith({
    OrderDetailStatus? status,
    OrderModel? order,
    String? errorMessage,
    PaymentInfoModel? paymentInfo,
    UserModel? placedByUser,
    ReturnRequestModel? returnRequest,
    bool clearError = false,
  }) {
    return OrderDetailState(
      status: status ?? this.status,
      order: order ?? this.order,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      paymentInfo: paymentInfo ?? this.paymentInfo,
      placedByUser: placedByUser ?? this.placedByUser,
      returnRequest: returnRequest ?? this.returnRequest,
    );
  }
}