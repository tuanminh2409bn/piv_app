import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/user_model.dart'; // Model người dùng đã có

abstract class UserProfileRepository {
  /// Lấy thông tin hồ sơ của người dùng dựa trên userId từ Firestore.
  Future<Either<Failure, UserModel>> getUserProfile(String userId);

  /// Cập nhật thông tin hồ sơ người dùng trên Firestore.
  /// Truyền vào một đối tượng UserModel đã được cập nhật.
  Future<Either<Failure, Unit>> updateUserProfile(UserModel user);
}
