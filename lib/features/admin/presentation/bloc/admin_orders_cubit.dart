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
        developer.log('AdminOrdersCubit: Failed to fetch all orders - ${failure.message}', name: 'AdminOrdersCubit');
        emit(state.copyWith(status: AdminOrdersStatus.error, errorMessage: failure.message));
      },
          (orders) {
        developer.log('AdminOrdersCubit: Fetched ${orders.length} orders successfully.', name: 'AdminOrdersCubit');
        emit(state.copyWith(status: AdminOrdersStatus.success, orders: orders));
      },
    );
  }

  /// Cập nhật trạng thái của một đơn hàng
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    // Không emit trạng thái loading ở đây để tránh làm toàn bộ danh sách tải lại,
    // tạo cảm giác giật lag. Chúng ta sẽ xử lý loading trên từng item riêng.
    // emit(state.copyWith(status: AdminOrdersStatus.updating));

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
}
