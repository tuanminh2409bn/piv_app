// lib/data/models/spin_history_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class SpinHistoryModel extends Equatable {
  final String id;
  final String userId;
  final String userDisplayName;
  final String campaignId;
  final String campaignName;
  final String rewardName;
  final DateTime spunAt;

  const SpinHistoryModel({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    required this.campaignId,
    required this.campaignName,
    required this.rewardName,
    required this.spunAt,
  });

  @override
  List<Object?> get props => [id, userId, userDisplayName, campaignId, campaignName, rewardName, spunAt];

  factory SpinHistoryModel.fromSnap(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>? ?? {};
    return SpinHistoryModel(
      id: snap.id,
      userId: data['userId'] as String? ?? '',
      userDisplayName: data['userDisplayName'] as String? ?? 'N/A',
      campaignId: data['campaignId'] as String? ?? '',
      campaignName: data['campaignName'] as String? ?? '',
      rewardName: data['rewardName'] as String? ?? 'Không có giải',
      spunAt: (data['spunAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }
}