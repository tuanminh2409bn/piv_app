//lib/features/vouchers/data/repositories/voucher_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:intl/intl.dart';
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
  Stream<List<VoucherModel>> getAllVouchers() {
    return _firestore
        .collection('vouchers')
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
  Future<Either<Failure, List<VoucherModel>>> getActiveVouchers() async {
    try {
      // Lấy toàn bộ để lọc trong memory, tránh lỗi Index Firestore
      final snapshot = await _firestore
          .collection('vouchers')
          .get();
      
      final now = DateTime.now();
      final vouchers = snapshot.docs
          .map((doc) => VoucherModel.fromSnapshot(doc))
          .where((v) => v.status == VoucherStatus.active && now.isBefore(v.expiresAt.toDate()))
          .toList();
      
      // Sắp xếp theo ngày hết hạn gần nhất trước
      vouchers.sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
          
      return Right(vouchers);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Lỗi Firestore'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VoucherModel>> applyVoucher({
    required String code,
    required String userId,
    required String userRole,
    required double subtotal,
    List<String> cartCategoryIds = const [],
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
      if (subtotal < voucher.minOrderValue) {
        final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
        return Left(ServerFailure('Đơn hàng chưa đủ ${formatter.format(voucher.minOrderValue)} để áp dụng mã này.'));
      }

      // Kiểm tra danh mục áp dụng
      if (voucher.applicableCategory != 'all') {
        if (!cartCategoryIds.contains(voucher.applicableCategory)) {
           String catName = voucher.applicableCategory == 'foliar_fertilizer' ? 'Phân bón lá' : 'Phân bón gốc';
           return Left(ServerFailure('Mã voucher này chỉ áp dụng cho $catName.'));
        }
      }

      // Kiểm tra mục tiêu (Target Validation)
      // Lấy thông tin user hiện tại để kiểm tra
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final salesRepId = userData?['salesRepId'];

      if (voucher.targetType == 'specific_agents') {
        if (!voucher.targetUserIds.contains(userId)) {
          return Left(ServerFailure('Mã voucher này không áp dụng cho tài khoản của bạn.'));
        }
      } else if (voucher.targetType == 'specific_sales_reps') {
        if (salesRepId == null || !voucher.targetSalesRepIds.contains(salesRepId)) {
          return Left(ServerFailure('Mã voucher này không áp dụng cho đại lý thuộc quản lý của bạn.'));
        }
      } else {
        // targetType == 'all'
        // Nếu người tạo là NVKD, thì 'all' có nghĩa là tất cả đại lý CỦA NVKD ĐÓ.
        // Cần lấy thông tin người tạo để biết họ là Admin hay NVKD.
        final creatorDoc = await _firestore.collection('users').doc(voucher.createdBy).get();
        final creatorRole = creatorDoc.data()?['role'];
        if (creatorRole == 'sales_rep' && salesRepId != voucher.createdBy) {
           return Left(ServerFailure('Mã voucher này chỉ áp dụng cho đại lý của NVKD đã tạo ra nó.'));
        }
      }

      return Right(voucher);
    } on FirebaseException catch (e) {
      return Left(ServerFailure('Lỗi Firebase: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Đã xảy ra lỗi không mong muốn: $e'));
    }
  }
}