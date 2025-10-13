// lib/features/orders/presentation/bloc/my_orders_state.dart

part of 'my_orders_cubit.dart';

enum MyOrdersStatus { initial, loading, success, error }

class MyOrdersState extends Equatable {
  final List<OrderModel> pendingApprovalOrders;
  final List<OrderModel> ongoingOrders;
  final List<OrderModel> completedOrders;
  // ----------------------------------------------------

  final MyOrdersStatus status;
  final String? errorMessage;

  const MyOrdersState({
    this.status = MyOrdersStatus.initial,
    this.pendingApprovalOrders = const [],
    this.ongoingOrders = const [],
    this.completedOrders = const [],
    this.errorMessage,
  });

  MyOrdersState copyWith({
    MyOrdersStatus? status,
    List<OrderModel>? pendingApprovalOrders,
    List<OrderModel>? ongoingOrders,
    List<OrderModel>? completedOrders,
    String? errorMessage,
  }) {
    return MyOrdersState(
      status: status ?? this.status,
      pendingApprovalOrders: pendingApprovalOrders ?? this.pendingApprovalOrders,
      ongoingOrders: ongoingOrders ?? this.ongoingOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, pendingApprovalOrders, ongoingOrders, completedOrders, errorMessage];
}