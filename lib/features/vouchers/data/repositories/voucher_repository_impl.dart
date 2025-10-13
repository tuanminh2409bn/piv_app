import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';
import 'package:piv_app/features/vouchers/domain/repositories/voucher_repository.dart';

class VoucherRepositoryImpl implements VoucherRepository {
  final FirebaseFirestore _firestore;

  VoucherRepositoryImpl({required FirebaseFirestore firestore}) : _firestore = firestore;

  @override
  Stream<List<VoucherModel>> getVouchersBySalesRep(String salesRepId) {
    return _firestore
        .collection('vouchers')
        .where('createdBy', isEqualTo: salesRepId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => VoucherModel.fromSnapshot(doc)).toList();
    });
  }

  @override
  Future<Either<Failure, void>> addVoucher(VoucherModel voucher) async {
    try {
      await _firestore.collection('vouchers').doc(voucher.id).set(voucher.toMap());
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Lỗi không xác định'));
    }
  }

  @override
  Future<Either<Failure, void>> updateVoucher(VoucherModel voucher) async {
    try {
      await _firestore.collection('vouchers').doc(voucher.id).update(voucher.toMap());
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Lỗi không xác định'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteVoucher(String voucherId) async {
    try {
      await _firestore.collection('vouchers').doc(voucherId).delete();
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Lỗi không xác định'));
    }
  }

  @override
  Future<Either<Failure, VoucherModel>> applyVoucher({
    required String code,
    required String userId,
    required String userRole,
  }) async {
    try {
      final doc = await _firestore.collection('vouchers').doc(code).get();
      if (!doc.exists) {
        return Left(ServerFailure('Mã voucher không tồn tại.'));
      }
      final voucher = VoucherModel.fromSnapshot(doc);

      if (voucher.status != VoucherStatus.active) {
        return Left(ServerFailure('Mã voucher không hoạt động.'));
      }
      if (DateTime.now().isAfter(voucher.expiresAt.toDate())) {
        return Left(ServerFailure('Mã voucher đã hết hạn.'));
      }
      if (voucher.maxUses != 0 && voucher.usedCount >= voucher.maxUses) {
        return Left(ServerFailure('Mã voucher đã hết lượt sử dụng.'));
      }

      return Right(voucher);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Đã xảy ra lỗi không mong muốn: $e'));
    }
  }
}