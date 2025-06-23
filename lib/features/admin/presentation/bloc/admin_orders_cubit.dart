import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';
import 'dart:developer' as developer;

part 'admin_orders_state.dart';

class AdminOrdersCubit extends Cubit<AdminOrdersState> {
  final OrderRepository _orderRepository;

  AdminOrdersCubit({required OrderRepository orderRepository})
      : _orderRepository = orderRepository,
        super(const AdminOrdersState());

  Future<void> fetchAllOrders() async {
    emit(state.copyWith(status: AdminOrdersStatus.loading));
    developer.log('AdminOrdersCubit: Fetching all orders...', name: 'AdminOrdersCubit');

    final result = await _orderRepository.getAllOrders();

    result.fold(
          (failure) {
        emit(state.copyWith(status: AdminOrdersStatus.error, errorMessage: failure.message));
      },
          (orders) {
        emit(state.copyWith(
          status: AdminOrdersStatus.success,
          allOrders: orders,
        ));
        // Sau khi tải, áp dụng lại bộ lọc và tìm kiếm hiện tại
        _applyFiltersAndSearch();
      },
    );
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final result = await _orderRepository.updateOrderStatus(orderId, newStatus);
    result.fold(
          (failure) {
        emit(state.copyWith(status: AdminOrdersStatus.error, errorMessage: failure.message));
      },
          (_) {
        fetchAllOrders();
      },
    );
  }

  void filterOrdersByStatus(String filter) {
    emit(state.copyWith(currentFilter: filter));
    _applyFiltersAndSearch();
  }

  void searchOrders(String query) {
    emit(state.copyWith(searchQuery: query));
    _applyFiltersAndSearch();
  }

  // --- HÀM HELPER TRUNG TÂM ĐỂ LỌC VÀ TÌM KIẾM ---
  void _applyFiltersAndSearch() {
    // Bắt đầu với danh sách đầy đủ
    List<OrderModel> listToProcess = List.from(state.allOrders);

    // 1. Áp dụng bộ lọc trạng thái
    final activeStatuses = {'pending', 'processing', 'shipped'};
    if (state.currentFilter != 'all') {
      switch (state.currentFilter) {
        case 'active':
          listToProcess = listToProcess.where((order) => activeStatuses.contains(order.status)).toList();
          break;
        case 'completed':
          listToProcess = listToProcess.where((order) => order.status == 'completed').toList();
          break;
        case 'cancelled':
          listToProcess = listToProcess.where((order) => order.status == 'cancelled').toList();
          break;
      }
    }

    // 2. Áp dụng tìm kiếm trên kết quả đã lọc
    final query = state.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      listToProcess = listToProcess.where((order) {
        final orderIdMatch = order.id?.toLowerCase().contains(query) ?? false;
        final customerNameMatch = order.shippingAddress.recipientName.toLowerCase().contains(query);
        final customerPhoneMatch = order.shippingAddress.phoneNumber.contains(query);
        return orderIdMatch || customerNameMatch || customerPhoneMatch;
      }).toList();
    }

    // 3. Cập nhật state với kết quả cuối cùng
    emit(state.copyWith(filteredOrders: listToProcess, status: AdminOrdersStatus.success));
  }
}