part of 'sales_rep_cubit.dart';

enum SalesRepStatus { initial, loading, success, error }

class SalesRepState extends Equatable {
  final SalesRepStatus status;
  final List<UserModel> myAgents;
  final List<UserModel> pendingAgents; // Thêm danh sách đại lý chờ duyệt
  final String? errorMessage;

  const SalesRepState({
    this.status = SalesRepStatus.initial,
    this.myAgents = const [],
    this.pendingAgents = const [], // Khởi tạo giá trị
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, myAgents, pendingAgents, errorMessage];

  SalesRepState copyWith({
    SalesRepStatus? status,
    List<UserModel>? myAgents,
    List<UserModel>? pendingAgents,
    String? errorMessage,
  }) {
    return SalesRepState(
      status: status ?? this.status,
      myAgents: myAgents ?? this.myAgents,
      pendingAgents: pendingAgents ?? this.pendingAgents,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}