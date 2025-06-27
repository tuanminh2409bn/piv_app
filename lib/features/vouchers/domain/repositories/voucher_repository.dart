import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';

// Đây là bản thiết kế (abstract class) cho các chức năng liên quan đến Voucher
abstract class VoucherRepository {
  /// NVKD tạo một voucher mới
  Future<Either<Failure, Unit>> createVoucher(VoucherModel voucher);

  /// NVKD lấy danh sách các voucher của mình
  Future<Either<Failure, List<VoucherModel>>> getVouchersBySalesRep(String salesRepId);

  /// NVKD cập nhật thông tin một voucher
  Future<Either<Failure, Unit>> updateVoucher(VoucherModel voucher);

  /// NVKD xóa một voucher
  Future<Either<Failure, Unit>> deleteVoucher(String voucherId);

  /// Đại lý áp dụng một voucher vào giỏ hàng
  Future<Either<Failure, VoucherModel>> applyVoucher({
    required String code,
    required String userId, // ID của đại lý đang áp dụng
  });
}
