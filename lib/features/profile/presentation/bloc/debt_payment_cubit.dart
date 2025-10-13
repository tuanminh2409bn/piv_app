// lib/features/profile/presentation/bloc/debt_payment_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';
import 'dart:developer' as developer;

part 'debt_payment_state.dart';

class DebtPaymentCubit extends Cubit<DebtPaymentState> {
  final AuthBloc _authBloc;
  final OrderRepository _orderRepository;

  DebtPaymentCubit({
    required AuthBloc authBloc,
    required OrderRepository orderRepository,
  })  : _authBloc = authBloc,
        _orderRepository = orderRepository,
        super(const DebtPaymentState()) {
    _loadInitialData();
  }

  void _loadInitialData() {
    final authState = _authBloc.state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      // --- BẮT ĐẦU SỬA LỖI ---
      // Khởi tạo người dùng nhưng số tiền thanh toán ban đầu là 0
      emit(state.copyWith(
        currentUser: user,
        amountToPay: 0.0,
      ));
      // --- KẾT THÚC SỬA LỖI ---
    }
  }

  void updateAmountToPay(double amount) {
    // Equatable sẽ tự động kiểm tra và chỉ phát ra state mới nếu giá trị thực sự thay đổi
    emit(state.copyWith(amountToPay: amount));
  }

  void clearError() {
    emit(state.copyWith(status: DebtPaymentStatus.initial, clearError: true));
  }

  Future<void> createDebtPaymentOrder() async {
    // --- BẮT ĐẦU SỬA LỖI ---
    // Kiểm tra lại giá trị amountToPay từ state mới nhất
    final currentAmountToPay = state.amountToPay;
    if (state.currentUser.isEmpty || state.currentUser.debtAmount <= 0) {
      emit(state.copyWith(status: DebtPaymentStatus.error, errorMessage: "Bạn không có công nợ để thanh toán."));
      return;
    }
    if (currentAmountToPay <= 0 || currentAmountToPay > state.currentUser.debtAmount) {
      emit(state.copyWith(status: DebtPaymentStatus.error, errorMessage: "Số tiền thanh toán không hợp lệ."));
      return;
    }
    // --- KẾT THÚC SỬA LỖI ---

    emit(state.copyWith(status: DebtPaymentStatus.loading));

    final remainingDebt = state.currentUser.debtAmount - currentAmountToPay;

    final debtOrder = OrderModel(
      userId: state.currentUser.id,
      items: const [],
      shippingAddress: state.currentUser.addresses.firstWhere((a) => a.isDefault, orElse: () => state.currentUser.addresses.first),
      subtotal: 0,
      shippingFee: 0,
      discount: 0,
      total: 0,
      paymentMethod: 'bank_transfer',
      status: 'pending',
      finalTotal: currentAmountToPay,
      salesRepId: state.currentUser.salesRepId,
      debtAmount: state.currentUser.debtAmount,
      paidAmount: currentAmountToPay,
      remainingDebt: remainingDebt,
    );

    final result = await _orderRepository.createOrder(
      debtOrder,
      clearCart: false,
    );

    result.fold(
          (failure) {
        emit(state.copyWith(status: DebtPaymentStatus.error, errorMessage: failure.message));
      },
          (orderId) {
        developer.log('Debt payment order created successfully: $orderId', name: 'DebtPaymentCubit');
        emit(state.copyWith(status: DebtPaymentStatus.success, newOrderId: orderId));
      },
    );
  }
}