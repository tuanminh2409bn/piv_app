import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';

part 'order_detail_state.dart';

class OrderDetailCubit extends Cubit<OrderDetailState> {
  final OrderRepository _orderRepository;
  final FirebaseFunctions _functions;
  StreamSubscription<OrderModel>? _orderSubscription;

  OrderDetailCubit({
    required OrderRepository orderRepository,
    required FirebaseFunctions functions,
  })  : _orderRepository = orderRepository,
        _functions = functions,
        super(const OrderDetailState());

  // <<< THAY THẾ: Dùng hàm này thay cho fetchOrderDetail >>>
  void listenToOrderDetail(String orderId) {
    if (orderId.isEmpty) {
      emit(state.copyWith(
          status: OrderDetailStatus.error,
          errorMessage: 'ID đơn hàng không hợp lệ.'));
      return;
    }
    emit(state.copyWith(status: OrderDetailStatus.loading));

    // Hủy subscription cũ nếu có để tránh memory leak
    _orderSubscription?.cancel();

    // Bắt đầu lắng nghe stream mới từ repository
    _orderSubscription = _orderRepository.getOrderStreamById(orderId).listen(
          (order) {
        // Mỗi khi có dữ liệu mới từ stream (ví dụ: chiết khấu được cập nhật),
        // cubit sẽ phát ra một trạng thái success mới với dữ liệu mới.
        developer.log("Received update for order ${order.id}", name: "OrderDetailCubit");
        emit(state.copyWith(status: OrderDetailStatus.success, order: order));
      },
      onError: (error) {
        // Xử lý lỗi từ stream
        developer.log("Error listening to order: $error", name: "OrderDetailCubit");
        emit(state.copyWith(
            status: OrderDetailStatus.error,
            errorMessage: 'Lỗi lắng nghe đơn hàng: $error'));
      },
    );
  }

  // <<< HÀM MỚI: Để khởi tạo thanh toán online >>>
  Future<void> initiateOnlinePayment() async {
    if (state.order == null) return;

    emit(state.copyWith(status: OrderDetailStatus.creatingPaymentUrl));
    try {
      final order = state.order!;
      // Gọi đến Callable Function chúng ta đã tạo
      final HttpsCallable callable = _functions.httpsCallable('createVnpayPaymentUrl');

      final response = await callable.call<Map<String, dynamic>>({
        'orderId': order.id,
        'amount': order.finalTotal.toInt(), // VNPAY yêu cầu số nguyên
        'orderInfo': 'Thanh toan cho don hang #${order.id?.substring(0, 8)}',
      });

      final url = response.data['checkoutUrl'] as String?;
      if (url != null) {
        // Phát ra trạng thái mới chứa link thanh toán
        emit(state.copyWith(
          status: OrderDetailStatus.paymentUrlCreated,
          paymentUrl: url,
        ));
      } else {
        throw Exception('URL thanh toán không hợp lệ.');
      }
    } catch (e) {
      developer.log('Error creating payment URL: $e', name: 'OrderDetailCubit');
      emit(state.copyWith(
        status: OrderDetailStatus.error,
        errorMessage: 'Không thể tạo link thanh toán. Vui lòng thử lại.',
      ));
    }
  }

  // Hàm này để reset lại trạng thái sau khi đã xử lý xong URL
  void resetPaymentUrlStatus() {
    emit(state.copyWith(status: OrderDetailStatus.success, forcePaymentUrlToNull: true));
  }

  // <<< QUAN TRỌNG: Hủy subscription khi Cubit bị đóng >>>
  @override
  Future<void> close() {
    _orderSubscription?.cancel();
    return super.close();
  }
}