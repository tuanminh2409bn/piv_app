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

  /// Tải tất cả các đơn hàng trong hệ thống
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
        // Sau khi tải, áp dụng lại bộ lọc hiện tại
        filterOrdersByStatus(state.currentFilter);
      },
    );
  }

  /// Cập nhật trạng thái của một đơn hàng
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    // Không emit loading ở đây để tránh làm toàn bộ danh sách tải lại,
    // tạo cảm giác giật lag. Chúng ta sẽ xử lý loading trên từng item riêng nếu cần.

    final result = await _orderRepository.updateOrderStatus(orderId, newStatus);

    result.fold(
          (failure) {
        // Có thể emit một lỗi tạm thời hoặc hiển thị SnackBar
        emit(state.copyWith(status: AdminOrdersStatus.error, errorMessage: failure.message));
      },
          (_) {
        // Sau khi cập nhật thành công, tải lại toàn bộ danh sách để đảm bảo dữ liệu mới nhất.
        fetchAllOrders();
      },
    );
  }

  /// Lọc danh sách người dùng theo trạng thái
  void filterOrdersByStatus(String filter) {
    final activeStatuses = {'pending', 'processing', 'shipped'};

    List<OrderModel> listToFilter;

    switch (filter) {
      case 'active':
        listToFilter = state.allOrders.where((order) => activeStatuses.contains(order.status)).toList();
        break;
      case 'completed':
        listToFilter = state.allOrders.where((order) => order.status == 'completed').toList();
        break;
      case 'cancelled':
        listToFilter = state.allOrders.where((order) => order.status == 'cancelled').toList();
        break;
      default: // 'all'
        listToFilter = state.allOrders;
    }
    emit(state.copyWith(filteredOrders: listToFilter, currentFilter: filter, status: AdminOrdersStatus.success));
  }

  /// Tìm kiếm đơn hàng dựa trên từ khóa
  void searchOrders(String query) {
    // Đầu tiên, lấy danh sách đã được lọc theo trạng thái làm danh sách cơ sở
    final activeStatuses = {'pending', 'processing', 'shipped'};
    List<OrderModel> baseList;
    switch (state.currentFilter) {
      case 'active': baseList = state.allOrders.where((order) => activeStatuses.contains(order.status)).toList(); break;
      case 'completed': baseList = state.allOrders.where((order) => order.status == 'completed').toList(); break;
      case 'cancelled': baseList = state.allOrders.where((order) => order.status == 'cancelled').toList(); break;
      default: baseList = state.allOrders;
    }

    if (query.isEmpty) {
      emit(state.copyWith(filteredOrders: baseList));
      return;
    }

    final lowerCaseQuery = query.toLowerCase();
    final filtered = baseList.where((order) {
      final orderIdMatch = order.id?.toLowerCase().contains(lowerCaseQuery) ?? false;
      final customerNameMatch = order.shippingAddress.recipientName.toLowerCase().contains(lowerCaseQuery);
      final customerPhoneMatch = order.shippingAddress.phoneNumber.contains(query); // Tìm SĐT không cần lowercase
      return orderIdMatch || customerNameMatch || customerPhoneMatch;
    }).toList();

    emit(state.copyWith(filteredOrders: filtered));
  }
}