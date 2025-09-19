//lib/features/sales_rep/presentation/bloc/agent_orders_state.dart

part of 'agent_orders_cubit.dart';

enum AgentOrdersStatus { initial, loading, success, error }

class AgentOrdersState extends Equatable {
  final AgentOrdersStatus status;
  final List<OrderModel> orders;
  final String? errorMessage;

  const AgentOrdersState({
    this.status = AgentOrdersStatus.initial,
    this.orders = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, orders, errorMessage];

  AgentOrdersState copyWith({
    AgentOrdersStatus? status,
    List<OrderModel>? orders,
    String? errorMessage,
  }) {
    return AgentOrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}