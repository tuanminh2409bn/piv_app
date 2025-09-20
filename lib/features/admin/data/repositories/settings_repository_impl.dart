import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/features/admin/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final FirebaseFirestore _firestore;

  SettingsRepositoryImpl({required FirebaseFirestore firestore}) : _firestore = firestore;

  DocumentReference<Map<String, dynamic>> get _settingsDoc => _firestore.collection('settings').doc('main');

  @override
  Future<Either<Failure, double>> getCommissionRate() async {
    try {
      final snapshot = await _settingsDoc.get();
      if (snapshot.exists && snapshot.data() != null) {
        final rate = (snapshot.data()!['commissionRate'] as num?)?.toDouble() ?? 0.05;
        return Right(rate);
      }
      return const Right(0.05);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateCommissionRate(double newRate) async {
    try {
      await _settingsDoc.set({'commissionRate': newRate}, SetOptions(merge: true));
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}