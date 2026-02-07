import 'package:piv_app/data/models/return_policy_config_model.dart';

abstract class ReturnSettingsRepository {
  Future<ReturnPolicyConfigModel> getReturnPolicy();
}
