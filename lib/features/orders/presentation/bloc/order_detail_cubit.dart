import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';

part 'order_detail_state.dart';

class OrderDetailCubit extends Cubit<OrderDetailState> {
  final OrderRepository _orderRepository;

  OrderDetailCubit({required OrderRepository orderRepository})
      : _orderRepository = orderRepository,
        super(const OrderDetailState());

  Future<void> fetchOrderDetail(String orderId) async {
    if (orderId.isEmpty) {
      emit(state.copyWith(status: OrderDetailStatus.error, errorMessage: 'ID đơn hàng không hợp lệ.'));
      return;
    }
    emit(state.copyWith(status: OrderDetailStatus.loading));
    final result = await _orderRepository.getOrderById(orderId);
    result.fold(
          (failure) => emit(state.copyWith(status: OrderDetailStatus.error, errorMessage: failure.message)),
          (order) => emit(state.copyWith(status: OrderDetailStatus.success, order: order)),
    );
  }
}
