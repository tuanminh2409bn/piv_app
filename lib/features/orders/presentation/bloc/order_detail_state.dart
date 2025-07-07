part of 'order_detail_cubit.dart';

enum OrderDetailStatus { initial, loading, success, error, creatingPaymentUrl, paymentUrlCreated }

class OrderDetailState extends Equatable {
  final OrderDetailStatus status;
  final OrderModel? order;
  final String? errorMessage;
  final String? paymentUrl; // <<< THÊM MỚI: Để lưu link thanh toán

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
  }) {
    return OrderDetailState(
      status: status ?? this.status,
      order: order ?? this.order,
      errorMessage: errorMessage ?? this.errorMessage,
      paymentUrl: forcePaymentUrlToNull ? null : paymentUrl ?? this.paymentUrl,
    );
  }
}