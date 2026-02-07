part of 'agent_discount_cubit.dart';

enum AgentDiscountStatus { initial, loading, success, error }

class AgentDiscountState extends Equatable {
  final AgentDiscountStatus status;
  final DiscountRequestModel? pendingRequest; // Yêu cầu đang chờ duyệt (nếu có)
  final String? errorMessage;
  final String? successMessage;

  const AgentDiscountState({
    this.status = AgentDiscountStatus.initial,
    this.pendingRequest,
    this.errorMessage,
    this.successMessage,
  });

  AgentDiscountState copyWith({
    AgentDiscountStatus? status,
    DiscountRequestModel? pendingRequest,
    String? errorMessage,
    String? successMessage,
  }) {
    return AgentDiscountState(
      status: status ?? this.status,
      pendingRequest: pendingRequest ?? this.pendingRequest,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [status, pendingRequest, errorMessage, successMessage];
}
