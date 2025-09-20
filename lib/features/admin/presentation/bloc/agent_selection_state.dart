// lib/features/admin/presentation/bloc/agent_selection_state.dart
part of 'agent_selection_cubit.dart';

enum AgentSelectionStatus { initial, loading, success, error }

class AgentSelectionState extends Equatable {
  final AgentSelectionStatus status;
  final List<UserModel> allAgents;
  final List<UserModel> filteredAgents;
  final String? errorMessage;

  const AgentSelectionState({
    this.status = AgentSelectionStatus.initial,
    this.allAgents = const [],
    this.filteredAgents = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, allAgents, filteredAgents, errorMessage];

  AgentSelectionState copyWith({
    AgentSelectionStatus? status,
    List<UserModel>? allAgents,
    List<UserModel>? filteredAgents,
    String? errorMessage,
  }) {
    return AgentSelectionState(
      status: status ?? this.status,
      allAgents: allAgents ?? this.allAgents,
      filteredAgents: filteredAgents ?? this.filteredAgents,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}