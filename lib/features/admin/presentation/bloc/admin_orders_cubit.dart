import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';

part 'admin_orders_state.dart';

class AdminOrdersCubit extends Cubit<AdminOrdersState> {
  final OrderRepository _orderRepository;

  AdminOrdersCubit({required OrderRepository orderRepository})
      : _orderRepository = orderRepository,
        super(const AdminOrdersState());

  /// Chỉ cần lấy TẤT CẢ đơn hàng một lần.
  Future<void> fetchAllOrders() async {
    emit(state.copyWith(status: AdminOrdersStatus.loading));
    final result = await _orderRepository.getAllOrders();
    result.fold(
          (failure) => emit(state.copyWith(status: AdminOrdersStatus.error, errorMessage: failure.message)),
          (orders) => emit(state.copyWith(status: AdminOrdersStatus.success, allOrders: orders)),
    );
  }

  /// Cập nhật query tìm kiếm trong state. UI sẽ tự động cập nhật theo.
  void searchOrders(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  /// Cập nhật trạng thái đơn hàng và tải lại toàn bộ danh sách để đảm bảo dữ liệu mới nhất.
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final result = await _orderRepository.updateOrderStatus(orderId, newStatus);
    result.fold(
          (failure) {
        emit(state.copyWith(status: AdminOrdersStatus.error, errorMessage: failure.message));
      },
          (_) => fetchAllOrders(), // Tải lại danh sách sau khi cập nhật thành công
    );
  }
}