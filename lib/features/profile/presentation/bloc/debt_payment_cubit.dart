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
      emit(state.copyWith(
        currentUser: user,
        amountToPay: user.debtAmount > 0 ? user.debtAmount : 0,
      ));
    }
  }

  void updateAmountToPay(double amount) {
    emit(state.copyWith(amountToPay: amount));
  }

  Future<void> createDebtPaymentOrder() async {
    if (state.currentUser.isEmpty || state.currentUser.debtAmount <= 0) {
      emit(state.copyWith(status: DebtPaymentStatus.error, errorMessage: "Bạn không có công nợ để thanh toán."));
      return;
    }
    if (state.amountToPay <= 0 || state.amountToPay > state.currentUser.debtAmount) {
      emit(state.copyWith(status: DebtPaymentStatus.error, errorMessage: "Số tiền thanh toán không hợp lệ."));
      return;
    }

    emit(state.copyWith(status: DebtPaymentStatus.loading));

    final remainingDebt = state.currentUser.debtAmount - state.amountToPay;

    // Tạo một "đơn hàng trả nợ" đặc biệt không có sản phẩm
    final debtOrder = OrderModel(
      userId: state.currentUser.id,
      items: const [],
      // Lấy địa chỉ mặc định hoặc địa chỉ đầu tiên của người dùng
      shippingAddress: state.currentUser.addresses.firstWhere((a) => a.isDefault, orElse: () => state.currentUser.addresses.first),
      subtotal: 0,
      shippingFee: 0,
      discount: 0,
      total: 0, // Tiền hàng là 0
      paymentMethod: 'bank_transfer', // Mặc định là chuyển khoản
      status: 'pending', // Trạng thái chờ xử lý như đơn hàng bình thường
      finalTotal: state.amountToPay, // Tổng thanh toán chính là số tiền trả nợ
      salesRepId: state.currentUser.salesRepId,
      // Ghi lại lịch sử công nợ
      debtAmount: state.currentUser.debtAmount,
      paidAmount: state.amountToPay,
      remainingDebt: remainingDebt,
    );

    // Gọi hàm repository để tạo đơn hàng và cập nhật công nợ
    final result = await _orderRepository.createOrder(
      debtOrder,
      clearCart: false, // Không xóa giỏ hàng
      newDebtAmount: remainingDebt,
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