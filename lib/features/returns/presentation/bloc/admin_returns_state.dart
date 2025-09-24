part of 'admin_returns_cubit.dart';

enum AdminReturnsStatus { initial, loading, success, error }

class AdminReturnsState extends Equatable {
  final AdminReturnsStatus status;
  final List<ReturnRequestModel> allRequests;
  final String? errorMessage;

  const AdminReturnsState({
    this.status = AdminReturnsStatus.initial,
    this.allRequests = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, allRequests, errorMessage];

  AdminReturnsState copyWith({
    AdminReturnsStatus? status,
    List<ReturnRequestModel>? allRequests,
    String? errorMessage,
  }) {
    return AdminReturnsState(
      status: status ?? this.status,
      allRequests: allRequests ?? this.allRequests,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}