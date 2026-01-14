import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:piv_app/features/admin/data/models/discount_policy_model.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_settings_repository.dart';

class AdminSettingsRepositoryImpl implements AdminSettingsRepository {
  final FirebaseFirestore _firestore;

  AdminSettingsRepositoryImpl(this._firestore);

  @override
  Future<DiscountPolicyModel> getDiscountPolicy() async {
    try {
      final doc = await _firestore.collection('settings').doc('discount_policy').get();
      if (doc.exists && doc.data() != null) {
        return DiscountPolicyModel.fromJson(doc.data()!);
      } else {
        // Nếu chưa có, trả về mặc định
        return DiscountPolicyModel.defaultPolicy();
      }
    } catch (e) {
      throw Exception('Failed to load discount policy: $e');
    }
  }

  @override
  Future<void> updateDiscountPolicy(DiscountPolicyModel policy) async {
    try {
      await _firestore.collection('settings').doc('discount_policy').set(policy.toJson());
    } catch (e) {
      throw Exception('Failed to update discount policy: $e');
    }
  }
}
