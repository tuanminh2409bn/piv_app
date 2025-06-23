part of 'admin_orders_cubit.dart';

enum AdminOrdersStatus { initial, loading, success, error }

class AdminOrdersState extends Equatable {
  final AdminOrdersStatus status;
  final List<OrderModel> allOrders;
  final List<OrderModel> filteredOrders;
  final String? errorMessage;
  final String currentFilter;
  final String searchQuery; // Thêm trường để lưu trữ query tìm kiếm

  const AdminOrdersState({
    this.status = AdminOrdersStatus.initial,
    this.allOrders = const [],
    this.filteredOrders = const [],
    this.errorMessage,
    this.currentFilter = 'active',
    this.searchQuery = '', // Giá trị mặc định
  });

  @override
  List<Object?> get props => [status, allOrders, filteredOrders, errorMessage, currentFilter, searchQuery];

  AdminOrdersState copyWith({
    AdminOrdersStatus? status,
    List<OrderModel>? allOrders,
    List<OrderModel>? filteredOrders,
    String? errorMessage,
    String? currentFilter,
    String? searchQuery,
  }) {
    return AdminOrdersState(
      status: status ?? this.status,
      allOrders: allOrders ?? this.allOrders,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      errorMessage: errorMessage ?? this.errorMessage,
      currentFilter: currentFilter ?? this.currentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}