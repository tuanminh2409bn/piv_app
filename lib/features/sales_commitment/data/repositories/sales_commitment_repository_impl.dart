// lib/features/sales_commitment/data/repositories/sales_commitment_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/sales_commitment_model.dart';
import 'package:piv_app/features/sales_commitment/domain/repositories/sales_commitment_repository.dart';

class SalesCommitmentRepositoryImpl implements SalesCommitmentRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  SalesCommitmentRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  @override
  Future<Either<Failure, void>> createSalesCommitment({
    required double targetAmount,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final callable = _functions.httpsCallable('createSalesCommitment');
      await callable.call({
        'targetAmount': targetAmount,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      });
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      return Left(ServerFailure(e.message ?? 'Lỗi không xác định từ server.'));
    } catch (e) {
      return Left(ServerFailure('Không thể đăng ký cam kết: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> setSalesCommitmentDetails({
    required String commitmentId,
    required String detailsText,
  }) async {
    try {
      final callable = _functions.httpsCallable('setSalesCommitmentDetails');
      await callable.call({
        'commitmentId': commitmentId,
        'detailsText': detailsText,
      });
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      return Left(ServerFailure(e.message ?? 'Lỗi không xác định từ server.'));
    } catch (e) {
      return Left(ServerFailure('Không thể cập nhật cam kết: ${e.toString()}'));
    }
  }

  @override
  Stream<SalesCommitmentModel?> watchActiveCommitmentForUser(String userId) {
    return _firestore
        .collection('sales_commitments')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return SalesCommitmentModel.fromSnap(snapshot.docs.first);
    });
  }

  @override
  Stream<List<SalesCommitmentModel>> watchAllCommitments() {
    return _firestore
        .collection('sales_commitments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SalesCommitmentModel.fromSnap(doc))
          .toList();
    });
  }
}