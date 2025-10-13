// lib/features/orders/presentation/bloc/order_detail_cubit.dart

import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/data/models/payment_info_model.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:piv_app/features/returns/data/models/return_request_model.dart';
import 'package:piv_app/features/returns/domain/repositories/return_repository.dart';


part 'order_detail_state.dart';

class OrderDetailCubit extends Cubit<OrderDetailState> {
  final OrderRepository _orderRepository;
  final UserProfileRepository _userProfileRepository;
  final ReturnRepository _returnRepository;
  StreamSubscription<OrderModel>? _orderSubscription;
  StreamSubscription<ReturnRequestModel>? _returnRequestSubscription;

  OrderDetailCubit({
    required OrderRepository orderRepository,
    required UserProfileRepository userProfileRepository,
    required ReturnRepository returnRepository,
  })  : _orderRepository = orderRepository,
        _userProfileRepository = userProfileRepository,
        _returnRepository = returnRepository,
        super(const OrderDetailState());

  void listenToOrderDetail(String orderId) {
    if (orderId.isEmpty) {
      emit(state.copyWith(status: OrderDetailStatus.error, errorMessage: 'ID đơn hàng không hợp lệ.'));
      return;
    }
    emit(state.copyWith(status: OrderDetailStatus.loading));
    _orderSubscription?.cancel();

    _orderSubscription = _orderRepository.getOrderStreamById(orderId).listen(
          (order) async {
        developer.log("Received update for order ${order.id}", name: "OrderDetailCubit");

        UserModel? placedByUser;
        if (order.placedBy != null && order.placedBy!.userId.isNotEmpty) {
          final userResult = await _userProfileRepository.getUserProfile(order.placedBy!.userId);
          userResult.fold(
                (failure) => placedByUser = null,
                (user) => placedByUser = user,
          );
        }

        _returnRequestSubscription?.cancel();
        if (order.returnInfo?.returnRequestId != null && order.returnInfo!.returnRequestId.isNotEmpty) {
          _returnRequestSubscription = _returnRepository
              .watchReturnRequestById(order.returnInfo!.returnRequestId)
              .listen((returnRequest) {
            emit(state.copyWith(returnRequest: returnRequest));
          });
        }

        emit(state.copyWith(
          status: OrderDetailStatus.success,
          order: order,
          placedByUser: placedByUser,
        ));

        if (order.paymentStatus == 'unpaid') {
          _fetchPaymentInfo();
        }
      },
      onError: (error) {
        developer.log("Error listening to order: $error", name: "OrderDetailCubit");
        emit(state.copyWith(status: OrderDetailStatus.error, errorMessage: 'Lỗi lắng nghe đơn hàng: $error'));
      },
    );
  }

  Future<void> _fetchPaymentInfo() async {
    if (state.paymentInfo != null) return;
    final result = await _orderRepository.getPaymentInfo();
    result.fold(
          (failure) => developer.log("Could not fetch payment info: ${failure.message}", name: "OrderDetailCubit"),
          (info) => emit(state.copyWith(paymentInfo: info)),
    );
  }

  Future<void> approveOrder() async {
    if (state.order?.id == null) return;
    emit(state.copyWith(status: OrderDetailStatus.updating));
    final result = await _orderRepository.approveOrder(state.order!.id!);
    result.fold(
          (failure) => emit(state.copyWith(status: OrderDetailStatus.error, errorMessage: failure.message)),
          (_) {
        // Stream sẽ tự động cập nhật, không cần emit lại state để tránh ghi đè chiết khấu
      },
    );
  }

  Future<void> rejectOrder(String reason) async {
    if (state.order?.id == null) return;
    emit(state.copyWith(status: OrderDetailStatus.updating));
    final result = await _orderRepository.rejectOrder(orderId: state.order!.id!, reason: reason);
    result.fold(
          (failure) => emit(state.copyWith(status: OrderDetailStatus.error, errorMessage: failure.message)),
          (_) => emit(state.copyWith(status: OrderDetailStatus.success)),
    );
  }

  Future<void> notifyPaymentMade() async {
    if (state.order?.id == null) return;
    emit(state.copyWith(status: OrderDetailStatus.updatingPaymentStatus));
    final result = await _orderRepository.notifyPaymentMade(state.order!.id!);
    result.fold(
          (failure) => emit(state.copyWith(status: OrderDetailStatus.error, errorMessage: failure.message)),
          (_) { /* Stream tự cập nhật */ },
    );
  }

  @override
  Future<void> close() {
    _orderSubscription?.cancel();
    _returnRequestSubscription?.cancel();
    return super.close();
  }
}