part of 'accountant_agents_cubit.dart';

enum AccountantAgentsStatus { initial, loading, success, error }

class AccountantAgentsState extends Equatable {
  final AccountantAgentsStatus status;
  final List<UserModel> agents;
  final String? errorMessage;

  const AccountantAgentsState({
    this.status = AccountantAgentsStatus.initial,
    this.agents = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, agents, errorMessage];

  AccountantAgentsState copyWith({
    AccountantAgentsStatus? status,
    List<UserModel>? agents,
    String? errorMessage,
  }) {
    return AccountantAgentsState(
      status: status ?? this.status,
      agents: agents ?? this.agents,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}