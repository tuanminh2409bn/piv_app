part of 'admin_orders_cubit.dart';

enum AdminOrdersStatus { initial, loading, success, error }

class AdminOrdersState extends Equatable {
  const AdminOrdersState({
    this.status = AdminOrdersStatus.initial,
    this.allOrders = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  final AdminOrdersStatus status;
  final List<OrderModel> allOrders;
  final String searchQuery;
  final String? errorMessage;

  // Helper để kiểm tra một đơn hàng có khớp với query tìm kiếm không
  bool _matchesSearch(OrderModel order) {
    if (searchQuery.isEmpty) return true;
    final query = searchQuery.trim().toLowerCase();
    // Sử dụng các thuộc tính chính xác từ OrderModel
    final orderIdMatch = order.id?.toLowerCase().contains(query) ?? false;
    final customerNameMatch = order.shippingAddress.recipientName.toLowerCase().contains(query);
    final customerPhoneMatch = order.shippingAddress.phoneNumber.contains(query);
    return orderIdMatch || customerNameMatch || customerPhoneMatch;
  }

  // --- GETTERS TỰ ĐỘNG LỌC VÀ TÌM KIẾM ---

  // Lấy các đơn hàng "Cần xử lý" (pending, processing, shipped)
  List<OrderModel> get processingOrders {
    const activeStatuses = {'pending', 'processing', 'shipped'};
    return allOrders.where((order) {
      return activeStatuses.contains(order.status) && _matchesSearch(order);
    }).toList();
  }

  // Lấy các đơn hàng "Hoàn thành"
  List<OrderModel> get completedOrders {
    return allOrders.where((order) {
      return order.status == 'completed' && _matchesSearch(order);
    }).toList();
  }

  // Lấy "Tất cả" các đơn hàng phù hợp với bộ lọc tìm kiếm
  List<OrderModel> get visibleOrders {
    return allOrders.where(_matchesSearch).toList();
  }

  AdminOrdersState copyWith({
    AdminOrdersStatus? status,
    List<OrderModel>? allOrders,
    String? searchQuery,
    String? errorMessage,
  }) {
    return AdminOrdersState(
      status: status ?? this.status,
      allOrders: allOrders ?? this.allOrders,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, allOrders, searchQuery, errorMessage];
}