// lib/data/models/lucky_wheel_campaign_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// Model cho một "ô" phần thưởng trên vòng quay
class RewardModel extends Equatable {
  final String name;
  final int probability;
  final int? limit;
  final String? imageUrl;

  const RewardModel({
    required this.name,
    required this.probability,
    this.limit,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [name, probability, limit];

  factory RewardModel.fromMap(Map<String, dynamic> map) {
    return RewardModel(
      name: map['name'] as String? ?? 'N/A',
      probability: (map['probability'] as num? ?? 0).toInt(),
      limit: (map['limit'] as num?)?.toInt(),
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'probability': probability,
      'limit': limit,
      'imageUrl': imageUrl,
    };
  }
}

// Model cho một "thể lệ" để có lượt quay
class RuleModel extends Equatable {
  final String type; // 'DAILY_LOGIN', 'SPEND_THRESHOLD', 'OPEN_TO_ALL'
  final int spinsGranted;
  final double? amount;

  const RuleModel({
    required this.type,
    required this.spinsGranted,
    this.amount,
  });

  @override
  List<Object?> get props => [type, spinsGranted, amount];

  factory RuleModel.fromMap(Map<String, dynamic> map) {
    return RuleModel(
      type: map['type'] as String? ?? '',
      spinsGranted: (map['spinsGranted'] as num? ?? 0).toInt(),
      amount: (map['amount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'spinsGranted': spinsGranted,
      'amount': amount,
    };
  }
}

// Model chính cho một chiến dịch Vòng quay
class LuckyWheelCampaignModel extends Equatable {
  final String id;
  final String name;
  final bool isActive;
  final DateTime startDate;
  final DateTime endDate;
  final List<RuleModel> rules;
  final List<String> appliesToRole;
  final List<RewardModel> rewards;

  const LuckyWheelCampaignModel({
    required this.id,
    required this.name,
    required this.isActive,
    required this.startDate,
    required this.endDate,
    required this.rules,
    required this.appliesToRole,
    required this.rewards,
  });

  @override
  List<Object?> get props => [id, name, isActive, startDate, endDate, rules, appliesToRole, rewards];

  factory LuckyWheelCampaignModel.fromSnap(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>? ?? {};
    final wheelConfig = data['wheelConfig'] as Map<String, dynamic>? ?? {};

    return LuckyWheelCampaignModel(
      id: snap.id,
      name: data['name'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? false,
      startDate: (data['startDate'] as Timestamp? ?? Timestamp.now()).toDate(),
      endDate: (data['endDate'] as Timestamp? ?? Timestamp.now()).toDate(),
      rules: (data['rules'] as List<dynamic>?)
          ?.map((ruleMap) => RuleModel.fromMap(ruleMap as Map<String, dynamic>))
          .toList() ?? [],
      appliesToRole: List<String>.from(wheelConfig['appliesToRole'] ?? []),
      rewards: (wheelConfig['rewards'] as List<dynamic>?)
          ?.map((rewardMap) => RewardModel.fromMap(rewardMap as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isActive': isActive,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'rules': rules.map((rule) => rule.toMap()).toList(),
      'wheelConfig': {
        'appliesToRole': appliesToRole,
        'rewards': rewards.map((reward) => reward.toMap()).toList(),
      },
    };
  }
}