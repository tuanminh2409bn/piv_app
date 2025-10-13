// lib/features/sales_rep/presentation/bloc/sales_rep_state.dart

part of 'sales_rep_cubit.dart';

// Giữ nguyên enum để thể hiện các trạng thái tải
enum SalesRepStatus { initial, loading, success, error }

class SalesRepState extends Equatable {
  const SalesRepState({
    this.status = SalesRepStatus.initial,
    this.myAgents = const <UserModel>[], // Chỉ còn lại danh sách đại lý của tôi
    this.errorMessage,
  });

  final SalesRepStatus status;
  final List<UserModel> myAgents;
  final String? errorMessage;

  SalesRepState copyWith({
    SalesRepStatus? status,
    List<UserModel>? myAgents,
    String? errorMessage,
  }) {
    return SalesRepState(
      status: status ?? this.status,
      myAgents: myAgents ?? this.myAgents,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // Đã loại bỏ pendingAgents khỏi props
  @override
  List<Object?> get props => [status, myAgents, errorMessage];
}