import 'package:equatable/equatable.dart';

class ReturnPolicyConfigModel extends Equatable {
  final List<ReturnPolicyTier> tiers;
  final int maxReturnMonths;

  const ReturnPolicyConfigModel({
    required this.tiers,
    required this.maxReturnMonths,
  });

  factory ReturnPolicyConfigModel.defaultPolicy() {
    return const ReturnPolicyConfigModel(
      maxReturnMonths: 24,
      tiers: [
        ReturnPolicyTier(minMonths: 0, maxMonths: 3, penaltyPerCrate: 0),
        ReturnPolicyTier(minMonths: 3, maxMonths: 12, penaltyPerCrate: 150000),
        ReturnPolicyTier(minMonths: 12, maxMonths: 24, penaltyPerCrate: 300000),
      ],
    );
  }

  factory ReturnPolicyConfigModel.fromJson(Map<String, dynamic> json) {
    return ReturnPolicyConfigModel(
      maxReturnMonths: json['maxReturnMonths'] as int? ?? 24,
      tiers: (json['tiers'] as List<dynamic>?)
              ?.map((e) => ReturnPolicyTier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxReturnMonths': maxReturnMonths,
      'tiers': tiers.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [tiers, maxReturnMonths];
}

class ReturnPolicyTier extends Equatable {
  final int minMonths;
  final int maxMonths;
  final double penaltyPerCrate;

  const ReturnPolicyTier({
    required this.minMonths,
    required this.maxMonths,
    required this.penaltyPerCrate,
  });

  factory ReturnPolicyTier.fromJson(Map<String, dynamic> json) {
    return ReturnPolicyTier(
      minMonths: json['minMonths'] as int? ?? 0,
      maxMonths: json['maxMonths'] as int? ?? 0,
      penaltyPerCrate: (json['penaltyPerCrate'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minMonths': minMonths,
      'maxMonths': maxMonths,
      'penaltyPerCrate': penaltyPerCrate,
    };
  }

  @override
  List<Object?> get props => [minMonths, maxMonths, penaltyPerCrate];
}
