part of 'admin_discount_requests_cubit.dart';

enum AdminDiscountRequestsStatus { initial, loading, loaded, error }

class AdminDiscountRequestsState extends Equatable {
  final AdminDiscountRequestsStatus status;
  final List<DiscountRequestModel> requests;

  const AdminDiscountRequestsState({
    this.status = AdminDiscountRequestsStatus.initial,
    this.requests = const [],
  });

  AdminDiscountRequestsState copyWith({
    AdminDiscountRequestsStatus? status,
    List<DiscountRequestModel>? requests,
  }) {
    return AdminDiscountRequestsState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
    );
  }

  @override
  List<Object> get props => [status, requests];
}
