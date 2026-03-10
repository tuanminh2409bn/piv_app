part of 'debt_approval_cubit.dart';

enum DebtApprovalStatus { initial, loading, success, submitting, error }

class DebtApprovalState extends Equatable {
  final DebtApprovalStatus status;
  final List<DebtUpdateRequestModel> pendingRequests;
  final String? errorMessage;

  const DebtApprovalState({
    this.status = DebtApprovalStatus.initial,
    this.pendingRequests = const [],
    this.errorMessage,
  });

  DebtApprovalState copyWith({
    DebtApprovalStatus? status,
    List<DebtUpdateRequestModel>? pendingRequests,
    String? errorMessage,
  }) {
    return DebtApprovalState(
      status: status ?? this.status,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, pendingRequests, errorMessage];
}
