part of 'order_detail_cubit.dart';

enum OrderDetailStatus {
  initial,
  loading,
  success,
  error,
}

class OrderDetailState extends Equatable {
  final OrderDetailStatus status;
  final OrderModel? order;
  final String? errorMessage;

  const OrderDetailState({
    this.status = OrderDetailStatus.initial,
    this.order,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, order, errorMessage];

  OrderDetailState copyWith({
    OrderDetailStatus? status,
    OrderModel? order,
    String? errorMessage,
  }) {
    return OrderDetailState(
      status: status ?? this.status,
      order: order ?? this.order,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
