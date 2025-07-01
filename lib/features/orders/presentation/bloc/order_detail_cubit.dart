import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';
import 'dart:developer' as developer;

part 'order_detail_state.dart';

class OrderDetailCubit extends Cubit<OrderDetailState> {
  final OrderRepository _orderRepository;
  StreamSubscription<OrderModel>? _orderSubscription;

  OrderDetailCubit({required OrderRepository orderRepository})
      : _orderRepository = orderRepository,
        super(const OrderDetailState());

  void listenToOrderDetail(String orderId) {
    if (orderId.isEmpty) {
      emit(state.copyWith(
          status: OrderDetailStatus.error,
          errorMessage: 'ID đơn hàng không hợp lệ.'));
      return;
    }
    emit(state.copyWith(status: OrderDetailStatus.loading));

    // Hủy subscription cũ nếu có
    _orderSubscription?.cancel();

    // Bắt đầu lắng nghe stream mới
    _orderSubscription = _orderRepository.getOrderStreamById(orderId).listen(
          (order) {
        // Mỗi khi có dữ liệu mới từ stream, cập nhật state
        developer.log("Received update for order ${order.id}", name: "OrderDetailCubit");
        emit(state.copyWith(status: OrderDetailStatus.success, order: order));
      },
      onError: (error) {
        // Xử lý lỗi từ stream
        developer.log("Error listening to order: $error", name: "OrderDetailCubit");
        emit(state.copyWith(
            status: OrderDetailStatus.error,
            errorMessage: 'Lỗi lắng nghe đơn hàng: $error'));
      },
    );
  }

  @override
  Future<void> close() {
    // Rất quan trọng: phải hủy subscription khi Cubit bị đóng
    _orderSubscription?.cancel();
    return super.close();
  }
}