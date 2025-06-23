import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/user_model.dart';

abstract class AdminRepository {
  /// Lấy tất cả người dùng trong hệ thống.
  Future<Either<Failure, List<UserModel>>> getAllUsers();

  /// Cập nhật vai trò (role) và trạng thái (status) của một người dùng.
  Future<Either<Failure, Unit>> updateUser(
      String userId,
      String newRole,
      String newStatus,
      );

  // --- PHƯƠNG THỨC MỚI CHO NVKD ---
  /// Lấy danh sách các đại lý được quản lý bởi một NVKD.
  Future<Either<Failure, List<UserModel>>> getAgentsBySalesRepId(String salesRepId);
// ------------------------------------
}