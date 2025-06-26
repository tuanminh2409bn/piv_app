import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';

part 'agent_orders_state.dart';

class AgentOrdersCubit extends Cubit<AgentOrdersState> {
  final OrderRepository _orderRepository;

  AgentOrdersCubit({required OrderRepository orderRepository})
      : _orderRepository = orderRepository,
        super(const AgentOrdersState());

  Future<void> fetchOrders(String agentId) async {
    if (agentId.isEmpty) return;
    emit(state.copyWith(status: AgentOrdersStatus.loading));
    final result = await _orderRepository.getUserOrders(agentId);
    result.fold(
          (failure) => emit(state.copyWith(status: AgentOrdersStatus.error, errorMessage: failure.message)),
          (orders) => emit(state.copyWith(status: AgentOrdersStatus.success, orders: orders)),
    );
  }
}