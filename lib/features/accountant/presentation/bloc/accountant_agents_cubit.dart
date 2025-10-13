import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';

part 'accountant_agents_state.dart';

class AccountantAgentsCubit extends Cubit<AccountantAgentsState> {
  final UserProfileRepository _userProfileRepository;

  AccountantAgentsCubit({required UserProfileRepository userProfileRepository})
      : _userProfileRepository = userProfileRepository,
        super(const AccountantAgentsState());

  Future<void> fetchAllAgents() async {
    emit(state.copyWith(status: AccountantAgentsStatus.loading));
    final result = await _userProfileRepository.getAllAgents();
    result.fold(
          (failure) => emit(state.copyWith(status: AccountantAgentsStatus.error, errorMessage: failure.message)),
          (agents) => emit(state.copyWith(status: AccountantAgentsStatus.success, agents: agents)),
    );
  }
}