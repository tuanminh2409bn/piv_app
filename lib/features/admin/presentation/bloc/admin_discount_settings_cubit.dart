import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/features/admin/data/models/discount_policy_model.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_settings_repository.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_discount_settings_state.dart';

class AdminDiscountSettingsCubit extends Cubit<AdminDiscountSettingsState> {
  final AdminSettingsRepository _repository;

  AdminDiscountSettingsCubit(this._repository) : super(AdminDiscountSettingsInitial());

  Future<void> loadSettings() async {
    try {
      emit(AdminDiscountSettingsLoading());
      final policy = await _repository.getDiscountPolicy();
      emit(AdminDiscountSettingsLoaded(policy));
    } catch (e) {
      emit(AdminDiscountSettingsError(e.toString()));
    }
  }

  Future<void> updateSettings(DiscountPolicyModel newPolicy) async {
    try {
      emit(AdminDiscountSettingsLoading());
      await _repository.updateDiscountPolicy(newPolicy);
      emit(AdminDiscountSettingsLoaded(newPolicy));
    } catch (e) {
      emit(AdminDiscountSettingsError(e.toString()));
    }
  }
}
