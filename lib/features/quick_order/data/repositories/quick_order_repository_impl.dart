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

  // --- SỬA ĐỔI: Thêm currentUserId và logic lọc ---
  @override
  Future<List<ProductModel>> getProductsByIds(List<String> productIds, {String? currentUserId}) async {
    if (productIds.isEmpty) {
      return [];
    }

    // Fetch each document individually to avoid Firestore 'list' rule permission issues
    final futures = productIds.map((id) async {
      try {
        final doc = await _firestore.collection('products').doc(id).get();
        if (doc.exists) {
          return ProductModel.fromSnapshot(doc);
        }
      } catch (e) {
         // Ignore permission errors for individual files
      }
      return null;
    });

    final results = await Future.wait(futures);
    final products = results.whereType<ProductModel>().toList();

    // --- LOGIC LỌC MỚI ---
    // Chỉ giữ lại sản phẩm Public HOẶC sản phẩm Private mà user này sở hữu
    final allowedProducts = products.where((product) {
      if (!product.isPrivate) return true; // Sản phẩm chung
      return product.ownerAgentId == currentUserId; // Sản phẩm riêng đúng chủ
    }).toList();
    // --------------------

    final productMap = {for (var p in allowedProducts) p.id: p};

    final sortedProducts = productIds
        .map((id) => productMap[id])
        .where((p) => p != null)
        .cast<ProductModel>()
        .toList();

    return sortedProducts;
  }
// --- KẾT THÚC SỬA ĐỔI ---
}