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
          .orderBy('email') // Sắp xếp theo email cho dễ nhìn
          .get();

      final users = querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();

      developer.log('Fetched ${users.length} users.', name: 'AdminRepository');
      return Right(users);

    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase khi tải danh sách người dùng: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi tải danh sách người dùng: ${e.toString()}'));
    }
  }

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
}
