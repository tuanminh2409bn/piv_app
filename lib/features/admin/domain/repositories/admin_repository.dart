// lib/features/admin/domain/repositories/admin_repository.dart

import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/data/models/debt_update_request_model.dart';
import 'package:piv_app/features/admin/data/models/discount_policy_model.dart';
import 'package:piv_app/features/admin/data/models/quick_order_item_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';

abstract class AdminRepository {
  Future<Either<Failure, List<UserModel>>> getAllUsers();
  Stream<List<UserModel>> watchAllUsers(); // MỚI: Lắng nghe tất cả user

  Future<Either<Failure, Unit>> updateUser(
      String userId, String newRole, String newStatus);

  // Agent Management
  Future<Either<Failure, List<UserModel>>> getAgentsBySalesRepId(
      String salesRepId);
  Stream<List<UserModel>> watchAgentsBySalesRepId(
      String salesRepId); // MỚI: Lắng nghe đại lý theo NVKD
  Future<Either<Failure, List<UserModel>>> getUsersByIds(List<String> userIds);
  Future<Either<Failure, List<UserModel>>> getPendingAgentsBySalesRepId(
      String salesRepId);

  // Quick Order List Management
  Stream<List<QuickOrderItemModel>> getQuickOrderItems(String agentId);
  Future<void> addProductToQuickList(
      {required String agentId,
      required String productId,
      required String addedBy});
  Future<void> removeProductFromQuickList(
      {required String agentId, required String itemId});
  Future<List<ProductModel>> getProductsByIds(List<String> productIds);

  Future<Either<Failure, void>> updateUserDebt({
    required String userId,
    required double newDebtAmount,
    required String updatedBy,
  });

  Future<Either<Failure, void>> createDebtUpdateRequest({
    required String userId,
    required String userName,
    required double oldDebtAmount,
    required double newDebtAmount,
    required String requestedBy,
    required String requestedByName,
  });

  Stream<List<DebtUpdateRequestModel>> getPendingDebtUpdateRequests();

  Future<Either<Failure, void>> approveDebtUpdateRequest({
    required String requestId,
    required String adminId,
  });

  Future<Either<Failure, void>> rejectDebtUpdateRequest({
    required String requestId,
    required String adminId,
    required String reason,
  });

  Future<Either<Failure, void>> updateUserDiscountConfig({
    required String userId,
    required bool enabled,
    required AgentPolicy policy,
  });

  Future<Either<Failure, Map<String, dynamic>>> adjustProductPrices({
    required String adjustmentType,
    required double adjustmentValue,
    required String productTarget,
    required String agentTarget,
  });
}
