part of 'my_orders_cubit.dart'; // Sẽ tạo file my_orders_cubit.dart sau

enum MyOrdersStatus {
  initial, // Trạng thái ban đầu
  loading, // Đang tải danh sách đơn hàng
  success, // Tải thành công
  error,   // Có lỗi xảy ra
}

class MyOrdersState extends Equatable {
  final MyOrdersStatus status;
  final List<OrderModel> orders; // Danh sách các đơn hàng
  final String? errorMessage;

  const MyOrdersState({
    this.status = MyOrdersStatus.initial,
    this.orders = const [],
    this.errorMessage,
  });

  MyOrdersState copyWith({
    MyOrdersStatus? status,
    List<OrderModel>? orders,
    String? errorMessage,
  }) {
    return MyOrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, orders, errorMessage];
}
