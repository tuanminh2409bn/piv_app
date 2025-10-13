// lib/features/admin/domain/repositories/admin_repository.dart

import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/data/models/quick_order_item_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';

abstract class AdminRepository {
  Future<Either<Failure, List<UserModel>>> getAllUsers();
  Future<Either<Failure, Unit>> updateUser(String userId, String newRole, String newStatus,);
  Future<Either<Failure, Unit>> updateUserDebt({required String userId, required double newDebtAmount, required String updatedBy,});
  Future<Either<Failure, List<UserModel>>> getAgentsBySalesRepId(String salesRepId);
  Future<Either<Failure, List<UserModel>>> getUsersByIds(List<String> userIds);
  Future<Either<Failure, List<UserModel>>> getPendingAgentsBySalesRepId(String salesRepId);
  Stream<List<QuickOrderItemModel>> getQuickOrderItems(String agentId);
  Future<void> addProductToQuickList({required String agentId, required String productId, required String addedBy,});
  Future<void> removeProductFromQuickList({required String agentId, required String itemId,});
  Future<List<ProductModel>> getProductsByIds(List<String> productIds);
}