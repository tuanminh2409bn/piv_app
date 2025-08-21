// lib/features/orders/presentation/bloc/order_detail_cubit.dart

import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/data/models/payment_info_model.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';

part 'order_detail_state.dart';

class OrderDetailCubit extends Cubit<OrderDetailState> {
  final OrderRepository _orderRepository;
  StreamSubscription<OrderModel>? _orderSubscription;

  // --- THAY ĐỔI: Xóa bỏ FirebaseFunctions ---
  OrderDetailCubit({
    required OrderRepository orderRepository,
  })  : _orderRepository = orderRepository,
        super(const OrderDetailState());

  void listenToOrderDetail(String orderId) {
    if (orderId.isEmpty) {
      emit(state.copyWith(
          status: OrderDetailStatus.error,
          errorMessage: 'ID đơn hàng không hợp lệ.'));
      return;
    }
    emit(state.copyWith(status: OrderDetailStatus.loading));

    _orderSubscription?.cancel();

    _orderSubscription = _orderRepository.getOrderStreamById(orderId).listen(
          (order) {
        developer.log("Received update for order ${order.id}", name: "OrderDetailCubit");
        emit(state.copyWith(status: OrderDetailStatus.success, order: order));

        // --- THÊM MỚI: Nếu đơn hàng chưa thanh toán, tự động tải thông tin QR ---
        if (order.paymentStatus == 'unpaid') {
          _fetchPaymentInfo();
        }
      },
      onError: (error) {
        developer.log("Error listening to order: $error", name: "OrderDetailCubit");
        emit(state.copyWith(
            status: OrderDetailStatus.error,
            errorMessage: 'Lỗi lắng nghe đơn hàng: $error'));
      },
    );
  }

  // --- HÀM MỚI: Tải thông tin thanh toán của công ty ---
  Future<void> _fetchPaymentInfo() async {
    // Chỉ tải nếu chưa có để tránh gọi lại nhiều lần không cần thiết
    if (state.paymentInfo != null) return;

    final result = await _orderRepository.getPaymentInfo();
    result.fold(
          (failure) {
        // Không emit lỗi ở đây để không che mất chi tiết đơn hàng
        developer.log("Could not fetch payment info: ${failure.message}", name: "OrderDetailCubit");
      },
          (info) => emit(state.copyWith(paymentInfo: info)),
    );
  }

  // --- XÓA BỎ: Hàm `initiateOnlinePayment` và `resetPaymentUrlStatus` đã được xóa ---

  Future<void> approveOrder() async {
    if (state.order?.id == null) return;
    emit(state.copyWith(status: OrderDetailStatus.updating));
    final result = await _orderRepository.approveOrder(state.order!.id!);
    result.fold(
          (failure) => emit(state.copyWith(status: OrderDetailStatus.error, errorMessage: failure.message)),
          (_) {
        // Không cần emit success vì stream sẽ tự động cập nhật
        // Chỉ cần chuyển trạng thái về lại success để tắt loading
        emit(state.copyWith(status: OrderDetailStatus.success));
      },
    );
  }

  Future<void> rejectOrder(String reason) async {
    if (state.order?.id == null) return;
    emit(state.copyWith(status: OrderDetailStatus.updating));
    final result = await _orderRepository.rejectOrder(orderId: state.order!.id!, reason: reason);
    result.fold(
          (failure) => emit(state.copyWith(status: OrderDetailStatus.error, errorMessage: failure.message)),
          (_) {
        emit(state.copyWith(status: OrderDetailStatus.success));
      },
    );
  }

  // --- HÀM MỚI: Xử lý khi người dùng nhấn "Tôi đã chuyển khoản" ---
  Future<void> notifyPaymentMade() async {
    if (state.order?.id == null) return;
    emit(state.copyWith(status: OrderDetailStatus.updatingPaymentStatus));
    final result = await _orderRepository.notifyPaymentMade(state.order!.id!);
    result.fold(
          (failure) {
        emit(state.copyWith(status: OrderDetailStatus.error, errorMessage: failure.message));
      },
          (_) {
        // Stream sẽ tự động cập nhật UI, không cần làm gì thêm
        // Trạng thái sẽ tự chuyển về success trong hàm listenToOrderDetail
      },
    );
  }

  @override
  Future<void> close() {
    _orderSubscription?.cancel();
    return super.close();
  }
}