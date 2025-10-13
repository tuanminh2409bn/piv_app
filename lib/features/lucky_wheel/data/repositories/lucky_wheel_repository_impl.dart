// lib/features/lucky_wheel/data/repositories/lucky_wheel_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:piv_app/core/error/failure.dart';
import 'package:piv_app/data/models/lucky_wheel_campaign_model.dart';
import 'package:piv_app/data/models/spin_history_model.dart';
import 'package:piv_app/features/lucky_wheel/domain/repositories/lucky_wheel_repository.dart';

class LuckyWheelRepositoryImpl implements LuckyWheelRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  LuckyWheelRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instanceFor(region: 'asia-southeast1'),
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<Either<Failure, String>> grantDailyLoginSpin() async {
    try {
      final callable = _functions.httpsCallable('grantDailyLoginSpin');
      final result = await callable.call();
      return Right(result.data['message'] as String? ?? 'Đã nhận lượt quay.');
    } on FirebaseFunctionsException catch (e) {
      return Left(ServerFailure(e.message ?? 'Lỗi không xác định từ server.'));
    } catch (e) {
      return Left(ServerFailure('Không thể nhận lượt quay: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, RewardModel>> spinTheWheel() async {
    try {
      final callable = _functions.httpsCallable('spinTheWheel');
      final result = await callable.call();
      final rewardData = Map<String, dynamic>.from(result.data['reward']);
      return Right(RewardModel.fromMap(rewardData));
    } on FirebaseFunctionsException catch (e) {
      return Left(ServerFailure(e.message ?? 'Lỗi không xác định từ server.'));
    } catch (e) {
      return Left(ServerFailure('Không thể thực hiện quay: ${e.toString()}'));
    }
  }

  @override
  Stream<LuckyWheelCampaignModel?> watchActiveCampaign(String userRole) {
    return _firestore
        .collection('lucky_wheel_campaigns')
        .where('isActive', isEqualTo: true)
        .where('wheelConfig.appliesToRole', arrayContains: userRole)
        .where('startDate', isLessThanOrEqualTo: Timestamp.now())
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final campaign = LuckyWheelCampaignModel.fromSnap(doc);

      if (campaign.endDate.isBefore(DateTime.now())) {
        return null;
      }

      return campaign;
    });
  }

  @override
  Stream<List<SpinHistoryModel>> watchMySpinHistory() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('spin_history')
        .where('userId', isEqualTo: userId)
        .orderBy('spunAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => SpinHistoryModel.fromSnap(doc)).toList());
  }

  @override
  Stream<List<SpinHistoryModel>> watchAllSpinHistory() {
    return _firestore
        .collection('spin_history')
        .orderBy('spunAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => SpinHistoryModel.fromSnap(doc)).toList());
  }

  @override
  Future<Either<Failure, void>> createOrUpdateCampaign(LuckyWheelCampaignModel campaign) async {
    try {
      final data = campaign.toMap();
      if (campaign.id.isNotEmpty) {
        await _firestore.collection('lucky_wheel_campaigns').doc(campaign.id).update(data);
      } else {
        await _firestore.collection('lucky_wheel_campaigns').add(data);
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Không thể lưu chiến dịch: ${e.toString()}'));
    }
  }

  @override
  Stream<List<LuckyWheelCampaignModel>> watchAllCampaigns() {
    return _firestore
        .collection('lucky_wheel_campaigns')
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => LuckyWheelCampaignModel.fromSnap(doc)).toList());
  }
}