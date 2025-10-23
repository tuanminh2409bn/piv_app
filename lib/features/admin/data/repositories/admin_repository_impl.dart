// lib/features/admin/data/repositories/admin_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_repository.dart';
import 'dart:developer' as developer;
import 'package:piv_app/features/admin/data/models/quick_order_item_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';

class AdminRepositoryImpl implements AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Either<Failure, List<UserModel>>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('email')
          .get();

      final allUsers = querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();

      // ========== BẮT ĐẦU SỬA ĐỔI ==========
      // Lọc bỏ những người dùng có vai trò là 'guest' ở phía client
      final nonGuestUsers = allUsers.where((user) => user.role != 'guest').toList();

      developer.log('Fetched ${allUsers.length} total users, returning ${nonGuestUsers.length} non-guest users.', name: 'AdminRepository');

      // Trả về danh sách đã được lọc
      return Right(nonGuestUsers);
      // ========== KẾT THÚC SỬA ĐỔI ==========

    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi tải danh sách người dùng: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải danh sách người dùng: ${e.toString()}'));
    }
  }

  // ... (Toàn bộ các hàm còn lại trong file này được giữ nguyên) ...
  @override
  Future<Either<Failure, Unit>> updateUser(String userId, String newRole, String newStatus) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'status': newStatus,
      });
      developer.log('Updated user $userId to role: $newRole, status: $newStatus', name: 'AdminRepository');
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi cập nhật người dùng: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi cập nhật người dùng: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<UserModel>>> getAgentsBySalesRepId(String salesRepId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('salesRepId', isEqualTo: salesRepId)
          .orderBy('displayName')
          .get();

      final agents = querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();

      developer.log('Fetched ${agents.length} agents for Sales Rep ID: $salesRepId.', name: 'AdminRepository');
      return Right(agents);

    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi tải danh sách đại lý: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải danh sách đại lý: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<UserModel>>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) {
      return const Right([]);
    }
    try {
      // Truy vấn `whereIn` cho phép tìm nhiều document cùng lúc
      final querySnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds)
          .get();

      final users = querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
      return Right(users);
    } catch (e) {
      return Left(ServerFailure('Lỗi khi tải danh sách người dùng: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<UserModel>>> getPendingAgentsBySalesRepId(String salesRepId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('salesRepId', isEqualTo: salesRepId)
          .where('status', isEqualTo: 'pending_approval')
          .get();

      final users = querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
      return Right(users);
    } catch (e) {
      return Left(ServerFailure('Lỗi khi tải danh sách đại lý chờ duyệt: ${e.toString()}'));
    }
  }

  @override
  Stream<List<QuickOrderItemModel>> getQuickOrderItems(String agentId) {
    return _firestore
        .collection('quick_order_lists')
        .doc(agentId)
        .collection('items')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => QuickOrderItemModel.fromSnapshot(doc)).toList();
    });
  }

  @override
  Future<void> addProductToQuickList({
    required String agentId,
    required String productId,
    required String addedBy,
  }) async {
    try {
      // Kiểm tra xem sản phẩm đã tồn tại trong danh sách chưa để tránh trùng lặp
      final existing = await _firestore
          .collection('quick_order_lists')
          .doc(agentId)
          .collection('items')
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        await _firestore
            .collection('quick_order_lists')
            .doc(agentId)
            .collection('items')
            .add({
          'productId': productId,
          'addedAt': FieldValue.serverTimestamp(),
          'addedBy': addedBy,
        });
      }
    } catch (e) {
      // Bạn có thể log lỗi hoặc rethrow một Failure ở đây
      throw Exception('Lỗi khi thêm sản phẩm vào danh sách đặt nhanh: $e');
    }
  }

  @override
  Future<void> removeProductFromQuickList({
    required String agentId,
    required String itemId,
  }) async {
    try {
      await _firestore
          .collection('quick_order_lists')
          .doc(agentId)
          .collection('items')
          .doc(itemId)
          .delete();
    } catch (e) {
      throw Exception('Lỗi khi xoá sản phẩm khỏi danh sách đặt nhanh: $e');
    }
  }

  @override
  Future<List<ProductModel>> getProductsByIds(List<String> productIds) async {
    if (productIds.isEmpty) {
      return [];
    }

    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where(FieldPath.documentId, whereIn: productIds)
          .get();

      // Sử dụng fromSnapshot trực tiếp, vì nó đã bao gồm ID
      final products = querySnapshot.docs
          .map((doc) => ProductModel.fromSnapshot(doc))
          .toList();

      // Sắp xếp lại danh sách sản phẩm theo thứ tự ID ban đầu để đảm bảo
      // thứ tự hiển thị không bị thay đổi sau mỗi lần tải lại.
      final productMap = {for (var p in products) p.id: p};
      final sortedProducts = productIds
          .map((id) => productMap[id])
          .where((p) => p != null)
          .cast<ProductModel>()
          .toList();

      return sortedProducts;

    } catch (e) {
      developer.log('Lỗi khi lấy sản phẩm theo IDs: $e', name: 'AdminRepositoryImpl');
      rethrow;
    }
  }

  @override
  Future<Either<Failure, Unit>> updateUserDebt({
    required String userId,
    required double newDebtAmount,
    required String updatedBy, // Giữ lại tham số này, có thể hữu ích cho việc log hoặc kiểm tra sau này nếu cần
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      // --- THAY ĐỔI CHÍNH: Chỉ thực hiện cập nhật debtAmount ---
      await userRef.update({'debtAmount': newDebtAmount});
      // --- KẾT THÚC THAY ĐỔI ---

      // Ghi log (chỉ log debug, không ghi vào Firestore ở đây)
      developer.log('Manually updated debt for user $userId to $newDebtAmount by $updatedBy', name: 'AdminRepository');
      return const Right(unit);

    } on FirebaseException catch (e) {
      // Nếu lỗi là do permission, kiểm tra lại rule cho phép update 'debtAmount' trên collection 'users'
      developer.log('Firebase Error updating debt (manual): ${e.code} - ${e.message}', name: 'AdminRepositoryError');
      return Left(ServerFailure('Lỗi Firebase khi cập nhật công nợ: ${e.message}'));
    } catch (e) {
      developer.log('Unknown Error updating debt (manual): ${e.toString()}', name: 'AdminRepositoryError');
      return Left(ServerFailure('Lỗi không xác định khi cập nhật công nợ: ${e.toString()}'));
    }
  }
}