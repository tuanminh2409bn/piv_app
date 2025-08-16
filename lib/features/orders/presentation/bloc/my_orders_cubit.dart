import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'dart:async';
import 'dart:developer' as developer;

part 'my_orders_state.dart';

class MyOrdersCubit extends Cubit<MyOrdersState> {
  final OrderRepository _orderRepository;
  final AuthBloc _authBloc;
  StreamSubscription? _authSubscription;
  String _currentUserId = '';

  MyOrdersCubit({
    required OrderRepository orderRepository,
    required AuthBloc authBloc,
  })  : _orderRepository = orderRepository,
        _authBloc = authBloc,
        super(const MyOrdersState()) {

    // Lắng nghe trạng thái AuthBloc để biết userId và tải đơn hàng tương ứng
    _authSubscription = _authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        _currentUserId = authState.user.id;
        fetchMyOrders(); // Tải đơn hàng khi người dùng đăng nhập
      } else if (authState is AuthUnauthenticated) {
        _currentUserId = '';
        emit(const MyOrdersState()); // Xóa danh sách đơn hàng khi đăng xuất
      }
    });

    // Tải dữ liệu lần đầu nếu người dùng đã đăng nhập sẵn khi app khởi động
    final initialAuthState = _authBloc.state;
    if (initialAuthState is AuthAuthenticated) {
      _currentUserId = initialAuthState.user.id;
      fetchMyOrders();
    }
  }

  /// Tải lịch sử đơn hàng của người dùng hiện tại
  Future<void> fetchMyOrders() async {
    if (_currentUserId.isEmpty) {
      emit(state.copyWith(status: MyOrdersStatus.error, errorMessage: 'Vui lòng đăng nhập để xem đơn hàng.'));
      return;
    }

    emit(state.copyWith(status: MyOrdersStatus.loading));
    final result = await _orderRepository.getUserOrders(_currentUserId);

    result.fold(
          (failure) {
        emit(state.copyWith(status: MyOrdersStatus.error, errorMessage: failure.message));
      },
          (orders) {
        // --- LOGIC MỚI: Phân loại đơn hàng ---
        final pendingApproval = orders.where((o) => o.status == 'pending_approval').toList();
        final ongoing = orders.where((o) => ['pending', 'processing', 'shipped'].contains(o.status)).toList();
        final completed = orders.where((o) => ['completed', 'cancelled', 'rejected'].contains(o.status)).toList();

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
    return super.close();
  }
}
