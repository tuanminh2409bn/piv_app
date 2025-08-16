part of 'order_detail_cubit.dart';

enum OrderDetailStatus { initial, loading, success, error, creatingPaymentUrl, paymentUrlCreated, updating }

class OrderDetailState extends Equatable {
  final OrderDetailStatus status;
  final OrderModel? order;
  final String? errorMessage;
  final String? paymentUrl;

  const OrderDetailState({
    this.status = OrderDetailStatus.initial,
    this.order,
    this.errorMessage,
    this.paymentUrl,
  });

  @override
  List<Object?> get props => [status, order, errorMessage, paymentUrl];

  OrderDetailState copyWith({
    OrderDetailStatus? status,
    OrderModel? order,
    String? errorMessage,
    String? paymentUrl,
    bool forcePaymentUrlToNull = false,
    bool clearError = false,
  }) {
    return OrderDetailState(
      status: status ?? this.status,
      order: order ?? this.order,
      errorMessage: errorMessage ?? this.errorMessage,
      paymentUrl: forcePaymentUrlToNull ? null : paymentUrl ?? this.paymentUrl,
    );
  }
}