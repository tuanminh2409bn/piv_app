import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:piv_app/data/models/special_price_model.dart';
import 'package:piv_app/features/admin/domain/repositories/special_price_repository.dart';

class SpecialPriceRepositoryImpl implements SpecialPriceRepository {
  final FirebaseFirestore firestore;

  SpecialPriceRepositoryImpl(this.firestore);

  @override
  Future<List<SpecialPriceModel>> getSpecialPrices(String userId) async {
    final snapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('special_prices')
        .get();

    return snapshot.docs
        .map((doc) => SpecialPriceModel.fromSnapshot(doc, userId))
        .toList();
  }

  @override
  Future<void> setSpecialPrice(
      String userId, String productId, double price, String adminId) async {
    final specialPrice = SpecialPriceModel(
      userId: userId,
      productId: productId,
      price: price,
      updatedBy: adminId,
    );
    
    await firestore
        .collection('users')
        .doc(userId)
        .collection('special_prices')
        .doc(productId)
        .set(specialPrice.toMap());
  }

  @override
  Future<void> removeSpecialPrice(String userId, String productId) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('special_prices')
        .doc(productId)
        .delete();
  }

  @override
  Future<void> toggleUseGeneralPrice(String userId, bool useGeneralPrice) async {
    await firestore.collection('users').doc(userId).update({
      'useGeneralPrice': useGeneralPrice,
    });
  }

  @override
  Stream<bool> watchUseGeneralPrice(String userId) {
    return firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return true;
      final data = doc.data();
      if (data == null || !data.containsKey('useGeneralPrice')) return true;
      return data['useGeneralPrice'] as bool;
    });
  }
}
