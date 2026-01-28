import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:piv_app/data/models/special_price_model.dart';
import 'package:piv_app/data/models/price_request_model.dart';
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

  // --- Price Approval Implementation ---

  @override
  Future<void> createPriceRequest(PriceRequestModel request) async {
    await firestore.collection('price_requests').add(request.toMap());
  }

  @override
  Stream<List<PriceRequestModel>> watchPendingRequests() {
    return firestore
        .collection('price_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PriceRequestModel.fromSnapshot(doc))
            .toList());
  }

  @override
  Stream<PriceRequestModel?> watchPendingRequestForAgent(String agentId) {
    return firestore
        .collection('price_requests')
        .where('agentId', isEqualTo: agentId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return PriceRequestModel.fromSnapshot(snapshot.docs.first);
          }
          return null;
        });
  }

  @override
  Future<void> cancelRequest(String requestId) async {
    await firestore.collection('price_requests').doc(requestId).delete();
  }

  @override
  Future<void> approveRequest(PriceRequestModel request, String adminId) async {
    final batch = firestore.batch();
    final requestRef = firestore.collection('price_requests').doc(request.id);

    // 1. Apply batch changes
    for (var item in request.items) {
      final specialPriceRef = firestore
          .collection('users')
          .doc(request.agentId)
          .collection('special_prices')
          .doc(item.productId);

      if (item.newPrice <= 0) {
        batch.delete(specialPriceRef);
      } else {
        final specialPriceData = {
          'userId': request.agentId,
          'productId': item.productId,
          'price': item.newPrice,
          'updatedBy': adminId,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        batch.set(specialPriceRef, specialPriceData);
      }
    }

    // 2. Update request status
    batch.update(requestRef, {
      'status': 'approved',
      'approvedBy': adminId,
      'approvedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  Future<void> rejectRequest(String requestId, String reason) async {
    await firestore.collection('price_requests').doc(requestId).update({
      'status': 'rejected',
      'rejectionReason': reason,
      'rejectedAt': FieldValue.serverTimestamp(),
    });
  }
}
