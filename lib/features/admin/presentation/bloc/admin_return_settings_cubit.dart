import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/data/models/return_policy_config_model.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_settings_repository.dart';
import 'admin_return_settings_state.dart';

class AdminReturnSettingsCubit extends Cubit<AdminReturnSettingsState> {
  final AdminSettingsRepository _repository;

  AdminReturnSettingsCubit({required AdminSettingsRepository repository})
      : _repository = repository,
        super(AdminReturnSettingsLoading());

  Future<void> loadPolicy() async {
    emit(AdminReturnSettingsLoading());
    try {
      final policy = await _repository.getReturnPolicy();
      emit(AdminReturnSettingsLoaded(policy));
    } catch (e) {
      emit(AdminReturnSettingsError(e.toString()));
    }
  }

  Future<void> updatePolicy(ReturnPolicyConfigModel policy) async {
    emit(AdminReturnSettingsLoading());
    try {
      await _repository.updateReturnPolicy(policy);
      emit(AdminReturnSettingsLoaded(policy));
    } catch (e) {
      emit(AdminReturnSettingsError(e.toString()));
    }
  }
}
