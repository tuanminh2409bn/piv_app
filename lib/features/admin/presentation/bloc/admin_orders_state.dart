// lib/features/admin/presentation/bloc/admin_orders_state.dart

part of 'admin_orders_cubit.dart';

enum AdminOrdersStatus { initial, loading, success, error, updating }

class AdminOrdersState extends Equatable {
  const AdminOrdersState({
    this.status = AdminOrdersStatus.initial,
    this.allOrders = const [],
    this.searchQuery = '',
    this.errorMessage,
    this.usersMap = const {},
  });

  final AdminOrdersStatus status;
  final List<OrderModel> allOrders;
  final String searchQuery;
  final String? errorMessage;
  final Map<String, UserModel> usersMap;

  bool _matchesSearch(OrderModel order) {
    if (searchQuery.isEmpty) return true;
    final query = searchQuery.trim().toLowerCase();
    final orderIdMatch = order.id?.toLowerCase().contains(query) ?? false;
    final customerNameMatch = order.shippingAddress.recipientName.toLowerCase().contains(query);
    final customerPhoneMatch = order.shippingAddress.phoneNumber.contains(query);
    return orderIdMatch || customerNameMatch || customerPhoneMatch;
  }

  List<OrderModel> get processingOrders {
    const activeStatuses = {'pending', 'processing', 'shipped'};
    return allOrders.where((order) {
      return activeStatuses.contains(order.status) && _matchesSearch(order);
    }).toList();
  }

  List<OrderModel> get completedOrders {
    return allOrders.where((order) {
      return order.status == 'completed' && _matchesSearch(order);
    }).toList();
  }

  List<OrderModel> get visibleOrders {
    return allOrders.where(_matchesSearch).toList();
  }

  AdminOrdersState copyWith({
    AdminOrdersStatus? status,
    List<OrderModel>? allOrders,
    String? searchQuery,
    String? errorMessage,
    Map<String, UserModel>? usersMap,
  }) {
    return AdminOrdersState(
      status: status ?? this.status,
      allOrders: allOrders ?? this.allOrders,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
      usersMap: usersMap ?? this.usersMap,
    );
  }

  @override
  List<Object?> get props => [status, allOrders, searchQuery, errorMessage, usersMap];
}