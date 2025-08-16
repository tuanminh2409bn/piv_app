// lib/features/admin/presentation/bloc/admin_orders_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/data/models/user_model.dart'; // --- THÊM MỚI ---
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart'; // --- THÊM MỚI ---

part 'admin_orders_state.dart';

class AdminOrdersCubit extends Cubit<AdminOrdersState> {
  final OrderRepository _orderRepository;
  // --- THÊM MỚI ---
  final UserProfileRepository _userProfileRepository;

  AdminOrdersCubit({
    required OrderRepository orderRepository,
    // --- THÊM MỚI ---
    required UserProfileRepository userProfileRepository,
  })  : _orderRepository = orderRepository,
  // --- THÊM MỚI ---
        _userProfileRepository = userProfileRepository,
        super(const AdminOrdersState());

  /// --- HÀM NÂNG CẤP HOÀN CHỈNH ---
  /// Lấy tất cả đơn hàng, sau đó lấy thông tin người dùng liên quan.
  Future<void> fetchAllOrders() async {
    emit(state.copyWith(status: AdminOrdersStatus.loading));
    final ordersResult = await _orderRepository.getAllOrders();

    await ordersResult.fold(
      // Nếu lỗi ngay từ lúc lấy đơn hàng
          (failure) async => emit(state.copyWith(status: AdminOrdersStatus.error, errorMessage: failure.message)),

      // Nếu lấy đơn hàng thành công, tiếp tục lấy thông tin người dùng
          (orders) async {
        // 1. Thu thập tất cả các ID người dùng cần thiết (không trùng lặp)
        final userIds = <String>{};
        for (final order in orders) {
          userIds.add(order.userId);
          if (order.placedBy != null) {
            userIds.add(order.placedBy!.userId);
          }
        }

        if (userIds.isEmpty) {
          // Không có user nào để lấy, emit luôn
          emit(state.copyWith(status: AdminOrdersStatus.success, allOrders: orders, usersMap: {}));
          return;
        }

        // 2. Gọi repository để lấy danh sách người dùng
        final usersResult = await _userProfileRepository.getUsersByIds(userIds.toList());

        usersResult.fold(
          // Nếu lỗi khi lấy người dùng, vẫn hiển thị đơn hàng nhưng báo lỗi
                (failure) {
              emit(state.copyWith(
                status: AdminOrdersStatus.error,
                allOrders: orders, // Vẫn giữ lại danh sách đơn hàng đã có
                errorMessage: 'Không thể tải tên người dùng: ${failure.message}',
              ));
            },
            // 3. Nếu thành công, tạo Map và emit state cuối cùng
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
          (_) => fetchAllOrders(), // Tải lại toàn bộ dữ liệu (cả đơn hàng và người dùng) sau khi cập nhật
    );
  }
}