import 'package:piv_app/features/admin/data/models/discount_policy_model.dart';
import 'package:piv_app/data/models/return_policy_config_model.dart';

abstract class AdminSettingsRepository {
  Future<DiscountPolicyModel> getDiscountPolicy();
  Future<void> updateDiscountPolicy(DiscountPolicyModel policy);

  Future<ReturnPolicyConfigModel> getReturnPolicy();
  Future<void> updateReturnPolicy(ReturnPolicyConfigModel policy);
}
