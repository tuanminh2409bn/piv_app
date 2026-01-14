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

  /// Yêu cầu hủy cam kết (Admin hủy ngay, Staff gửi yêu cầu)
  Future<Either<Failure, void>> requestCancelCommitment({
    required String commitmentId,
    required String reason,
  });

  /// Admin duyệt yêu cầu hủy
  Future<Either<Failure, void>> approveCancelCommitment({
    required String commitmentId,
  });

  /// Admin từ chối yêu cầu hủy
  Future<Either<Failure, void>> rejectCancelCommitment({
    required String commitmentId,
  });

  /// Lấy cam kết đang hoạt động của một người dùng cụ thể
  Stream<SalesCommitmentModel?> watchActiveCommitmentForUser(String userId);

  /// Lấy lịch sử tất cả các cam kết của một người dùng
  Stream<List<SalesCommitmentModel>> watchCommitmentHistoryForUser(String userId);

  /// Lấy danh sách tất cả các cam kết (dành cho Admin/NVKD)
  Stream<List<SalesCommitmentModel>> watchAllCommitments();
}
