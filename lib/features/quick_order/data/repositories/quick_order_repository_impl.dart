// lib/features/quick_order/data/repositories/quick_order_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:piv_app/features/admin/data/models/quick_order_item_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/quick_order/domain/repositories/quick_order_repository.dart';

class QuickOrderRepositoryImpl implements QuickOrderRepository {
  final FirebaseFirestore _firestore;

  QuickOrderRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<QuickOrderItemModel>> getQuickOrderItems(String agentId) {
    return _firestore
        .collection('quick_order_lists')
        .doc(agentId)
        .collection('items')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => QuickOrderItemModel.fromSnapshot(doc))
          .toList();
    });
  }

  @override
  Future<List<ProductModel>> getProductsByIds(List<String> productIds) async {
    if (productIds.isEmpty) {
      return [];
    }
    final querySnapshot = await _firestore
        .collection('products')
        .where(FieldPath.documentId, whereIn: productIds)
        .get();

    final products = querySnapshot.docs
        .map((doc) => ProductModel.fromSnapshot(doc))
        .toList();

    final productMap = {for (var p in products) p.id: p};
    final sortedProducts = productIds
        .map((id) => productMap[id])
        .where((p) => p != null)
        .cast<ProductModel>()
        .toList();

    return sortedProducts;
  }
}