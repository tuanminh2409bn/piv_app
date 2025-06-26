import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/user_model.dart';

abstract class AdminRepository {
  Future<Either<Failure, List<UserModel>>> getAllUsers();

  Future<Either<Failure, Unit>> updateUser(
      String userId,
      String newRole,
      String newStatus,
      );

  Future<Either<Failure, List<UserModel>>> getAgentsBySalesRepId(String salesRepId);
  Future<Either<Failure, List<UserModel>>> getUsersByIds(List<String> userIds);
}