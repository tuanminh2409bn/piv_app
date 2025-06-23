part of 'sales_rep_cubit.dart';

enum SalesRepStatus { initial, loading, success, error }

class SalesRepState extends Equatable {
  final SalesRepStatus status;
  final List<UserModel> myAgents;
  final String? errorMessage;

  const SalesRepState({
    this.status = SalesRepStatus.initial,
    this.myAgents = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, myAgents, errorMessage];

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
}