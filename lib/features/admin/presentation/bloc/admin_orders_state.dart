part of 'admin_orders_cubit.dart'; // Sẽ tạo file admin_orders_cubit.dart sau

enum AdminOrdersStatus {
  initial, // Trạng thái ban đầu
  loading, // Đang tải danh sách đơn hàng
  success, // Tải thành công
  error,   // Có lỗi xảy ra
  updating, // Đang cập nhật trạng thái đơn hàng
}

class AdminOrdersState extends Equatable {
  final AdminOrdersStatus status;
  final List<OrderModel> orders; // Danh sách tất cả đơn hàng
  final String? errorMessage;
  // (Tùy chọn) Thêm bộ lọc để admin có thể lọc đơn hàng
  // final String currentFilter;

  const AdminOrdersState({
    this.status = AdminOrdersStatus.initial,
    this.orders = const [],
    this.errorMessage,
    // this.currentFilter = 'all',
  });

  AdminOrdersState copyWith({
    AdminOrdersStatus? status,
    List<OrderModel>? orders,
    String? errorMessage,
  }) {
    return AdminOrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, orders, errorMessage];
}
