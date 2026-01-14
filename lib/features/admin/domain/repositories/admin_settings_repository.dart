import 'package:piv_app/features/admin/data/models/discount_policy_model.dart';

abstract class AdminSettingsRepository {
  Future<DiscountPolicyModel> getDiscountPolicy();
  Future<void> updateDiscountPolicy(DiscountPolicyModel policy);
}
