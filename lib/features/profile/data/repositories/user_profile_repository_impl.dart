import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'dart:developer' as developer;

class UserProfileRepositoryImpl implements UserProfileRepository {
  final FirebaseFirestore _firestore;

  UserProfileRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Hàm helper để lấy tham chiếu đến collection 'users'
  CollectionReference<Map<String, dynamic>> get _usersCollection => _firestore.collection('users');

  @override
  Future<Either<Failure, UserModel>> getUserProfile(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        // Tạo đối tượng UserModel từ dữ liệu Firestore
        final user = UserModel.fromJson(docSnapshot.data()!);
        developer.log('Fetched profile for user: ${user.id}', name: 'UserProfileRepo');
        return Right(user);
      } else {
        // Trường hợp không tìm thấy document
        developer.log('User profile not found for ID: $userId', name: 'UserProfileRepo');
        return Left(ServerFailure('Không tìm thấy hồ sơ người dùng.'));
      }
    } on FirebaseException catch (e) {
      developer.log('FirebaseException in getUserProfile: ${e.message}', name: 'UserProfileRepo');
      return Left(ServerFailure('Lỗi Firebase: ${e.message}'));
    } catch (e) {
      developer.log('Unknown error in getUserProfile: ${e.toString()}', name: 'UserProfileRepo');
      return Left(ServerFailure('Lỗi không xác định khi tải hồ sơ: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateUserProfile(UserModel user) async {
    try {
      // Sử dụng phương thức `update` để chỉ cập nhật các trường được cung cấp trong Map
      // từ hàm toJson(), thay vì ghi đè toàn bộ document.
      // Điều này an toàn hơn và tránh xóa các trường không được quản lý bởi UserModel.
      await _usersCollection.doc(user.id).update(user.toJson());
      developer.log('Updated profile for user: ${user.id}', name: 'UserProfileRepo');
      return const Right(unit);
    } on FirebaseException catch (e) {
      developer.log('FirebaseException in updateUserProfile: ${e.message}', name: 'UserProfileRepo');
      return Left(ServerFailure('Lỗi Firebase khi cập nhật hồ sơ: ${e.message}'));
    } catch (e) {
      developer.log('Unknown error in updateUserProfile: ${e.toString()}', name: 'UserProfileRepo');
      return Left(ServerFailure('Lỗi không xác định khi cập nhật hồ sơ: ${e.toString()}'));
    }
  }
}
