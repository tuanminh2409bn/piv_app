part of 'admin_orders_cubit.dart';

enum AdminOrdersStatus { initial, loading, success, error }

class AdminOrdersState extends Equatable {
  final AdminOrdersStatus status;
  // Danh sách đầy đủ tất cả đơn hàng
  final List<OrderModel> allOrders;
  // Danh sách đơn hàng đã được lọc (dựa trên tìm kiếm hoặc bộ lọc trạng thái)
  final List<OrderModel> filteredOrders;
  final String? errorMessage;
  // Trạng thái bộ lọc hiện tại, ví dụ: 'active', 'completed'
  final String currentFilter;

  const AdminOrdersState({
    this.status = AdminOrdersStatus.initial,
    this.allOrders = const [],
    this.filteredOrders = const [],
    this.errorMessage,
    this.currentFilter = 'active', // Mặc định hiển thị các đơn hàng cần xử lý
  });

  @override
  List<Object?> get props => [status, allOrders, filteredOrders, errorMessage, currentFilter];

  AdminOrdersState copyWith({
    AdminOrdersStatus? status,
    List<OrderModel>? allOrders,
    List<OrderModel>? filteredOrders,
    String? errorMessage,
    String? currentFilter,
  }) {
    return AdminOrdersState(
      status: status ?? this.status,
      allOrders: allOrders ?? this.allOrders,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      errorMessage: errorMessage ?? this.errorMessage,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }
}