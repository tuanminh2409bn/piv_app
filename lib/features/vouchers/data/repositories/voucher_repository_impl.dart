import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';
import 'package:piv_app/features/vouchers/domain/repositories/voucher_repository.dart';
import 'dart:developer' as developer;

class VoucherRepositoryImpl implements VoucherRepository {
  final FirebaseFirestore _firestore;

  VoucherRepositoryImpl({required FirebaseFirestore firestore}) : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _vouchersCollection => _firestore.collection('vouchers');
  CollectionReference<Map<String, dynamic>> get _usersCollection => _firestore.collection('users');

  @override
  Future<Either<Failure, Unit>> createVoucher(VoucherModel voucher) async {
    try {
      // ID của document chính là mã code của voucher
      await _vouchersCollection.doc(voucher.id).set(voucher.toMap());
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<VoucherModel>>> getVouchersBySalesRep(String salesRepId) async {
    try {
      final snapshot = await _vouchersCollection
          .where('salesRepId', isEqualTo: salesRepId)
          .orderBy('createdAt', descending: true)
          .get();

      final vouchers = snapshot.docs.map((doc) => VoucherModel.fromSnapshot(doc)).toList();
      return Right(vouchers);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateVoucher(VoucherModel voucher) async {
    try {
      await _vouchersCollection.doc(voucher.id).update(voucher.toMap());
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteVoucher(String voucherId) async {
    try {
      await _vouchersCollection.doc(voucherId).delete();
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VoucherModel>> applyVoucher({required String code, required String userId}) async {
    try {
      // 1. Kiểm tra xem voucher có tồn tại không
      final voucherDoc = await _vouchersCollection.doc(code).get();
      if (!voucherDoc.exists) {
        return Left(ServerFailure("Mã giảm giá không tồn tại."));
      }

      final voucher = VoucherModel.fromSnapshot(voucherDoc);

      // 2. Kiểm tra các điều kiện của voucher
      if (!voucher.isActive) {
        return Left(ServerFailure("Mã giảm giá này không còn hoạt động."));
      }
      if (DateTime.now().isAfter(voucher.expiresAt.toDate())) {
        return Left(ServerFailure("Mã giảm giá đã hết hạn."));
      }
      if (voucher.maxUses != 0 && voucher.usesCount >= voucher.maxUses) {
        return Left(ServerFailure("Mã giảm giá đã hết lượt sử dụng."));
      }

      // 3. Kiểm tra xem đại lý có thuộc quyền quản lý của NVKD sở hữu voucher không
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) {
        return Left(ServerFailure("Không tìm thấy thông tin người dùng."));
      }
      final user = UserModel.fromJson(userDoc.data()!);

      if (user.salesRepId != voucher.salesRepId) {
        return Left(ServerFailure("Mã giảm giá này không hợp lệ cho tài khoản của bạn."));
      }

      // Nếu tất cả điều kiện đều hợp lệ, trả về voucher
      developer.log("Voucher '$code' applied successfully for user '$userId'", name: "VoucherRepo");
      return Right(voucher);

    } catch (e) {
      developer.log("Error applying voucher: $e", name: "VoucherRepo");
      return Left(ServerFailure("Đã có lỗi xảy ra khi áp dụng mã."));
    }
  }
}
