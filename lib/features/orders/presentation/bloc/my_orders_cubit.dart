// lib/features/orders/presentation/bloc/my_orders_cubit.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';

part 'my_orders_state.dart';

class MyOrdersCubit extends Cubit<MyOrdersState> {
  final OrderRepository _orderRepository;
  final AuthBloc _authBloc;
  StreamSubscription? _authSubscription;
  StreamSubscription<List<OrderModel>>? _ordersSubscription; // <<< THAY ĐỔI
  String _currentUserId = '';

  MyOrdersCubit({
    required OrderRepository orderRepository,
    required AuthBloc authBloc,
  })  : _orderRepository = orderRepository,
        _authBloc = authBloc,
        super(const MyOrdersState()) {
    _authSubscription = _authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        // Nếu user thay đổi, bắt đầu lắng nghe đơn hàng của user mới
        if (_currentUserId != authState.user.id) {
          _currentUserId = authState.user.id;
          watchMyOrders();
        }
      } else if (authState is AuthUnauthenticated) {
        _currentUserId = '';
        _ordersSubscription?.cancel(); // Hủy lắng nghe khi đăng xuất
        emit(const MyOrdersState());
      }
    });

    final initialAuthState = _authBloc.state;
    if (initialAuthState is AuthAuthenticated) {
      _currentUserId = initialAuthState.user.id;
      watchMyOrders();
    }
  }

  /// Lắng nghe stream đơn hàng của người dùng hiện tại
  void watchMyOrders() {
    if (_currentUserId.isEmpty) {
      emit(state.copyWith(
          status: MyOrdersStatus.error,
          errorMessage: 'Vui lòng đăng nhập để xem đơn hàng.'));
      return;
    }

    emit(state.copyWith(status: MyOrdersStatus.loading));
    _ordersSubscription?.cancel(); // Hủy subscription cũ trước khi tạo mới
    _ordersSubscription =
        _orderRepository.watchUserOrders(_currentUserId).listen(
              (orders) {
            // --- LOGIC PHÂN LOẠI ĐƠN HÀNG GIỮ NGUYÊN ---
            // THAY ĐỔI QUAN TRỌNG: Thêm các trạng thái đổi/trả vào tab "Đang xử lý"
            final pendingApproval =
            orders.where((o) => o.status == 'pending_approval').toList();

            final ongoing = orders
                .where((o) => [
              'pending',
              'processing',
              'shipped'
            ].contains(o.status) || o.returnInfo != null && [
              'pending_approval',
              'approved',
            ].contains(o.returnInfo!.returnStatus))
                .toList();

            final completed = orders
                .where((o) => [
              'completed',
              'cancelled',
              'rejected'
            ].contains(o.status) && (o.returnInfo == null || ![
              'pending_approval',
              'approved',
            ].contains(o.returnInfo!.returnStatus)))
                .toList();

            emit(state.copyWith(
              status: MyOrdersStatus.success,
              pendingApprovalOrders: pendingApproval,
              ongoingOrders: ongoing,
              completedOrders: completed,
            ));
          },
          onError: (error) {
            emit(state.copyWith(
                status: MyOrdersStatus.error,
                errorMessage: 'Không thể tải danh sách đơn hàng.'));
          },
        );
  }

  // Tạm thời giữ lại hàm fetch để dùng cho RefreshIndicator nếu cần
  Future<void> fetchMyOrders() async {
    // Logic của hàm này sẽ không được dùng để cập nhật tự động nữa
    // nhưng có thể được gọi thủ công
    if (_currentUserId.isEmpty) return;
    final result = await _orderRepository.getUserOrders(_currentUserId);
    result.fold(
          (failure) => null, // Không làm gì khi lỗi
          (orders) {
        final pendingApproval =
        orders.where((o) => o.status == 'pending_approval').toList();

        final ongoing = orders
            .where((o) => [
          'pending',
          'processing',
          'shipped'
        ].contains(o.status) || o.returnInfo != null && [
          'pending_approval',
          'approved',
        ].contains(o.returnInfo!.returnStatus))
            .toList();

        final completed = orders
            .where((o) => [
          'completed',
          'cancelled',
          'rejected'
        ].contains(o.status) && (o.returnInfo == null || ![
          'pending_approval',
          'approved',
        ].contains(o.returnInfo!.returnStatus)))
            .toList();

        emit(state.copyWith(
          status: MyOrdersStatus.success,
          pendingApprovalOrders: pendingApproval,
          ongoingOrders: ongoing,
          completedOrders: completed,
        ));
      },
    );
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _ordersSubscription?.cancel(); // <<< THAY ĐỔI
    return super.close();
  }
}