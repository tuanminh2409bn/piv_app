part of 'price_approval_cubit.dart';

enum PriceApprovalStatus { initial, loading, success, error }

class PriceApprovalState extends Equatable {
  final PriceApprovalStatus status;
  final List<PriceRequestModel> pendingRequests;
  final String? errorMessage;

  const PriceApprovalState({
    this.status = PriceApprovalStatus.initial,
    this.pendingRequests = const [],
    this.errorMessage,
  });

  PriceApprovalState copyWith({
    PriceApprovalStatus? status,
    List<PriceRequestModel>? pendingRequests,
    String? errorMessage,
  }) {
    return PriceApprovalState(
      status: status ?? this.status,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, pendingRequests, errorMessage];
}
