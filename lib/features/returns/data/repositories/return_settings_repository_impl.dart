import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:piv_app/data/models/return_policy_config_model.dart';
import 'package:piv_app/features/returns/domain/repositories/return_settings_repository.dart';

class ReturnSettingsRepositoryImpl implements ReturnSettingsRepository {
  final FirebaseFirestore _firestore;

  ReturnSettingsRepositoryImpl(this._firestore);

  @override
  Future<ReturnPolicyConfigModel> getReturnPolicy() async {
    try {
      final doc = await _firestore.collection('settings').doc('return_policy').get();
      if (doc.exists && doc.data() != null) {
        return ReturnPolicyConfigModel.fromJson(doc.data()!);
      } else {
        return ReturnPolicyConfigModel.defaultPolicy();
      }
    } catch (e) {
      // Fallback to default if error or offline (optional: log error)
      return ReturnPolicyConfigModel.defaultPolicy();
    }
  }
}
