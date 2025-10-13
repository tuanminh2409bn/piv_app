// lib/features/admin/presentation/bloc/agent_selection_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_repository.dart';

part 'agent_selection_state.dart';

class AgentSelectionCubit extends Cubit<AgentSelectionState> {
  final AdminRepository _adminRepository;

  AgentSelectionCubit({required AdminRepository adminRepository})
      : _adminRepository = adminRepository,
        super(const AgentSelectionState());

  Future<void> fetchAllAgents() async {
    emit(state.copyWith(status: AgentSelectionStatus.loading));
    final result = await _adminRepository.getAllUsers(); // Dùng lại hàm cũ
    result.fold(
          (failure) => emit(state.copyWith(
          status: AgentSelectionStatus.error, errorMessage: failure.message)),
          (users) {
        final agents = users
            .where((user) => user.role == 'agent_1' || user.role == 'agent_2')
            .toList();
        emit(state.copyWith(
          status: AgentSelectionStatus.success,
          allAgents: agents,
          filteredAgents: agents,
        ));
      },
    );
  }

  void searchAgents(String query) {
    if (query.isEmpty) {
      emit(state.copyWith(filteredAgents: state.allAgents));
      return;
    }
    final lowerCaseQuery = query.toLowerCase();
    final filtered = state.allAgents.where((agent) {
      final nameMatch = agent.displayName?.toLowerCase().contains(lowerCaseQuery) ?? false;
      final emailMatch = agent.email?.toLowerCase().contains(lowerCaseQuery) ?? false;
      return nameMatch || emailMatch;
    }).toList();

    emit(state.copyWith(filteredAgents: filtered));
  }
}