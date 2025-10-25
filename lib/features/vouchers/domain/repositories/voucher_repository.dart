// lib/features/vouchers/domain/repositories/voucher_repository.dart

import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';

abstract class VoucherRepository {
  // Sửa lại để trả về một Stream<List<VoucherModel>> cho real-time
  Stream<List<VoucherModel>> getVouchersBySalesRep(String salesRepId);

  // Thêm các hàm mới để quản lý voucher
  Future<Either<Failure, void>> addVoucher(VoucherModel voucher);
  Future<Either<Failure, void>> updateVoucher(VoucherModel voucher);
  Future<Either<Failure, void>> deleteVoucher(String voucherId);

  // Sửa lại hàm applyVoucher cho nhất quán
  Future<Either<Failure, VoucherModel>> applyVoucher({
    required String code,
    required String userId,
    required String userRole,
    required double subtotal,
  });
}