// lib/features/sales_commitment/presentation/bloc/agent/sales_commitment_agent_state.dart

part of 'sales_commitment_agent_cubit.dart';

enum SalesCommitmentAgentStatus { initial, loading, success, error }

class SalesCommitmentAgentState extends Equatable {
  final SalesCommitmentAgentStatus status;
  final SalesCommitmentModel? activeCommitment;
  final String? errorMessage;

  const SalesCommitmentAgentState({
    this.status = SalesCommitmentAgentStatus.initial,
    this.activeCommitment,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, activeCommitment, errorMessage];

  SalesCommitmentAgentState copyWith({
    SalesCommitmentAgentStatus? status,
    SalesCommitmentModel? activeCommitment,
    String? errorMessage,
    bool forceCommitmentToNull = false,
  }) {
    return SalesCommitmentAgentState(
      status: status ?? this.status,
      activeCommitment: forceCommitmentToNull ? null : activeCommitment ?? this.activeCommitment,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}