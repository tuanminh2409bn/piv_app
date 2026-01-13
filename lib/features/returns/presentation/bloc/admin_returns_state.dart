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

// --- THÊM MỚI CHO LOADER ---
class AdminReturnsLoading extends AdminReturnsState {}

class AdminReturnsError extends AdminReturnsState {
  final String message;
  const AdminReturnsError(this.message) : super(errorMessage: message, status: AdminReturnsStatus.error);

  @override
  List<Object?> get props => [message];
}

class AdminReturnRequestLoaded extends AdminReturnsState {
  final ReturnRequestModel request;
  const AdminReturnRequestLoaded(this.request) : super(status: AdminReturnsStatus.success);

  @override
  List<Object?> get props => [request];
}
