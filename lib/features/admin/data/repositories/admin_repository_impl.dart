// lib/features/admin/data/repositories/admin_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_repository.dart';
import 'dart:developer' as developer;

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
}