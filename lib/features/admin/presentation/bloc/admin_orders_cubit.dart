// lib/features/admin/presentation/bloc/admin_orders_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';

part 'admin_orders_state.dart';

class AdminOrdersCubit extends Cubit<AdminOrdersState> {
  final OrderRepository _orderRepository;
  final UserProfileRepository _userProfileRepository;

  AdminOrdersCubit({
    required OrderRepository orderRepository,
    required UserProfileRepository userProfileRepository,
  })  : _orderRepository = orderRepository,
        _userProfileRepository = userProfileRepository,
        super(const AdminOrdersState());

  Future<void> fetchAllOrders() async {
    if (isClosed) return;
    emit(state.copyWith(status: AdminOrdersStatus.loading));

    final ordersResult = await _orderRepository.getAllOrders();

    if (isClosed) return;

    await ordersResult.fold(
          (failure) async {
        if (isClosed) return;
        emit(state.copyWith(status: AdminOrdersStatus.error, errorMessage: failure.message));
      },
          (orders) async {
        final userIds = <String>{};
        for (final order in orders) {
          userIds.add(order.userId);
          if (order.placedBy != null) {
            userIds.add(order.placedBy!.userId);
          }
        }

        if (userIds.isEmpty) {
          if (isClosed) return;
          emit(state.copyWith(status: AdminOrdersStatus.success, allOrders: orders, usersMap: {}));
          return;
        }

        final usersResult = await _userProfileRepository.getUsersByIds(userIds.toList());

        // Kiểm tra lần cuối trước khi emit kết quả cuối cùng
        if (isClosed) return;

        usersResult.fold(
                (failure) {
              emit(state.copyWith(
                status: AdminOrdersStatus.error,
                allOrders: orders,
                errorMessage: 'Không thể tải tên người dùng: ${failure.message}',
              ));
            },
                (users) {
              final usersMap = {for (var user in users) user.id: user};
              emit(state.copyWith(
                status: AdminOrdersStatus.success,
                allOrders: orders,
                usersMap: usersMap,
              ));
            }
        );
      },
    );
  }

  void searchOrders(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final result = await _orderRepository.updateOrderStatus(orderId, newStatus);
    result.fold(
          (failure) {
        emit(state.copyWith(status: AdminOrdersStatus.error, errorMessage: failure.message));
      },
          (_) => fetchAllOrders(),
    );
  }

  Future<void> confirmOrderPayment(String orderId) async {
    emit(state.copyWith(status: AdminOrdersStatus.updating));
    final result = await _orderRepository.confirmOrderPayment(orderId);
    result.fold(
          (failure) {
        emit(state.copyWith(status: AdminOrdersStatus.error, errorMessage: failure.message));
      },
          (_) => fetchAllOrders(),
    );
  }

  Future<void> updateOrderStatusToShipped(String orderId, DateTime shippingDate) async {
    final result = await _orderRepository.updateOrderStatusToShipped(orderId, shippingDate);
    result.fold(
          (failure) {
        emit(state.copyWith(status: AdminOrdersStatus.error, errorMessage: failure.message));
      },
          (_) => fetchAllOrders(),
    );
  }
}