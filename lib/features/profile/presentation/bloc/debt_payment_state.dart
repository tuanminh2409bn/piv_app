// lib/features/profile/presentation/bloc/debt_payment_state.dart

part of 'debt_payment_cubit.dart';

enum DebtPaymentStatus { initial, loading, success, error }

class DebtPaymentState extends Equatable {
  final DebtPaymentStatus status;
  final UserModel currentUser;
  final double amountToPay;
  final String? newOrderId;
  final String? errorMessage;

  const DebtPaymentState({
    this.status = DebtPaymentStatus.initial,
    this.currentUser = UserModel.empty,
    this.amountToPay = 0.0,
    this.newOrderId,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, currentUser, amountToPay, newOrderId, errorMessage];

  DebtPaymentState copyWith({
    DebtPaymentStatus? status,
    UserModel? currentUser,
    double? amountToPay,
    String? newOrderId,
    String? errorMessage,
    bool clearError = false, // Tham số này sẽ được sử dụng
  }) {
    return DebtPaymentState(
      status: status ?? this.status,
      currentUser: currentUser ?? this.currentUser,
      amountToPay: amountToPay ?? this.amountToPay,
      newOrderId: newOrderId ?? this.newOrderId,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}