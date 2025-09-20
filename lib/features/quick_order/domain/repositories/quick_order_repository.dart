// lib/features/quick_order/domain/repositories/quick_order_repository.dart

import 'package:piv_app/features/admin/data/models/quick_order_item_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';

abstract class QuickOrderRepository {
  // Lấy danh sách các sản phẩm (chỉ có productId) trong Quick List của một đại lý
  Stream<List<QuickOrderItemModel>> getQuickOrderItems(String agentId);

  // Lấy danh sách sản phẩm đầy đủ từ một danh sách ID
  Future<List<ProductModel>> getProductsByIds(List<String> productIds);
}