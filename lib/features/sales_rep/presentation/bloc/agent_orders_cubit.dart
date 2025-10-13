//lib/features/sales_rep/presentation/bloc/agent_orders_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';

part 'agent_orders_state.dart';

class AgentOrdersCubit extends Cubit<AgentOrdersState> {
  final OrderRepository _orderRepository;
  final AuthBloc _authBloc; // <<< THÊM AUTHBLOC

  AgentOrdersCubit({
    required OrderRepository orderRepository,
    required AuthBloc authBloc, // <<< THÊM VÀO CONSTRUCTOR
  })  : _orderRepository = orderRepository,
        _authBloc = authBloc, // <<< THÊM VÀO CONSTRUCTOR
        super(const AgentOrdersState());

  Future<void> fetchOrders(String agentId) async {
    if (agentId.isEmpty) return;

    final authState = _authBloc.state;
    if (authState is! AuthAuthenticated) return; // Phải là NVKD đang đăng nhập

    emit(state.copyWith(status: AgentOrdersStatus.loading));

    // <<< SỬA LẠI: GỌI HÀM MỚI >>>
    final result = await _orderRepository.getOrdersForSalesRepByAgent(
      salesRepId: authState.user.id, // ID của NVKD
      agentId: agentId,             // ID của đại lý đang xem
    );

    result.fold(
          (failure) => emit(state.copyWith(status: AgentOrdersStatus.error, errorMessage: failure.message)),
          (orders) => emit(state.copyWith(status: AgentOrdersStatus.success, orders: orders)),
    );
  }
}