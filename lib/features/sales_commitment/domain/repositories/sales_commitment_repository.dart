// lib/features/sales_commitment/domain/repositories/sales_commitment_repository.dart

import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/sales_commitment_model.dart';

abstract class SalesCommitmentRepository {
  /// Đại lý đăng ký một cam kết mới
  Future<Either<Failure, void>> createSalesCommitment({
    required double targetAmount,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Admin/NVKD thiết lập chi tiết phần thưởng cho một cam kết
  Future<Either<Failure, void>> setSalesCommitmentDetails({
    required String commitmentId,
    required String detailsText,
  });

  /// Lấy cam kết đang hoạt động của một người dùng cụ thể
  Stream<SalesCommitmentModel?> watchActiveCommitmentForUser(String userId);

  /// Lấy danh sách tất cả các cam kết (dành cho Admin/NVKD)
  Stream<List<SalesCommitmentModel>> watchAllCommitments();
}