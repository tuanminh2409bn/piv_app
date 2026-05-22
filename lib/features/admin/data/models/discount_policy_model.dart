import 'package:cloud_firestore/cloud_firestore.dart';

class DiscountTier {
  final double minAmount;
  final double rate;

  DiscountTier({required this.minAmount, required this.rate});

  factory DiscountTier.fromJson(Map<String, dynamic> json) {
    return DiscountTier(
      minAmount: (json['minAmount'] as num).toDouble(),
      rate: (json['rate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minAmount': minAmount,
      'rate': rate,
    };
  }
}

class ProductTypePolicy {
  final List<DiscountTier> tiers;

  ProductTypePolicy({required this.tiers});

  factory ProductTypePolicy.fromJson(Map<String, dynamic> json) {
    var list = json['tiers'] as List? ?? [];
    List<DiscountTier> tiersList = list.map((i) => DiscountTier.fromJson(i)).toList();
    return ProductTypePolicy(tiers: tiersList);
  }

  Map<String, dynamic> toJson() {
    return {
      'tiers': tiers.map((e) => e.toJson()).toList(),
    };
  }
}

class AgentPolicy {
  final ProductTypePolicy foliar;
  final ProductTypePolicy root;

  AgentPolicy({required this.foliar, required this.root});

  factory AgentPolicy.fromJson(Map<String, dynamic> json) {
    return AgentPolicy(
      foliar: ProductTypePolicy.fromJson(json['foliar'] ?? {'tiers': []}),
      root: ProductTypePolicy.fromJson(json['root'] ?? {'tiers': []}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foliar': foliar.toJson(),
      'root': root.toJson(),
    };
  }
}

class AgentDueDaysPolicy {
  final int foliar;
  final int root;
  final int mixed;

  AgentDueDaysPolicy({required this.foliar, required this.root, required this.mixed});

  factory AgentDueDaysPolicy.fromJson(Map<String, dynamic> json) {
    return AgentDueDaysPolicy(
      foliar: json['foliar'] as int? ?? 30,
      root: json['root'] as int? ?? 30,
      mixed: json['mixed'] as int? ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foliar': foliar,
      'root': root,
      'mixed': mixed,
    };
  }
}

class AgentPromotionConfig {
  final bool allowDiscount;
  final bool allowVoucher;
  final bool allowPromotionDuringCommitment;

  AgentPromotionConfig({
    required this.allowDiscount, 
    required this.allowVoucher,
    required this.allowPromotionDuringCommitment,
  });

  factory AgentPromotionConfig.fromJson(Map<String, dynamic> json) {
    return AgentPromotionConfig(
      allowDiscount: json['allowDiscount'] as bool? ?? true,
      allowVoucher: json['allowVoucher'] as bool? ?? true,
      allowPromotionDuringCommitment: json['allowPromotionDuringCommitment'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowDiscount': allowDiscount,
      'allowVoucher': allowVoucher,
      'allowPromotionDuringCommitment': allowPromotionDuringCommitment,
    };
  }
}

class DiscountPolicyModel {
  final AgentPolicy agent1;
  final AgentPolicy agent2;
  final AgentDueDaysPolicy agent1DueDays;
  final AgentDueDaysPolicy agent2DueDays;
  final AgentPromotionConfig agent1PromotionConfig;
  final AgentPromotionConfig agent2PromotionConfig;
  final double vatPercentage;
  final bool globalAllowVoucherStacking;
  
  // Seasonal discount configurations
  final bool seasonalDiscountEnabled;
  final double seasonalDiscountRate;
  final DateTime? seasonalDiscountStart;
  final DateTime? seasonalDiscountEnd;

  DiscountPolicyModel({
    required this.agent1, 
    required this.agent2,
    required this.agent1DueDays,
    required this.agent2DueDays,
    required this.agent1PromotionConfig,
    required this.agent2PromotionConfig,
    this.vatPercentage = 10.0, // Default 10% VAT
    this.globalAllowVoucherStacking = false,
    this.seasonalDiscountEnabled = false,
    this.seasonalDiscountRate = 0.05, // Default 5%
    this.seasonalDiscountStart,
    this.seasonalDiscountEnd,
  });

  DiscountPolicyModel copyWith({
    AgentPolicy? agent1,
    AgentPolicy? agent2,
    AgentDueDaysPolicy? agent1DueDays,
    AgentDueDaysPolicy? agent2DueDays,
    AgentPromotionConfig? agent1PromotionConfig,
    AgentPromotionConfig? agent2PromotionConfig,
    double? vatPercentage,
    bool? globalAllowVoucherStacking,
    bool? seasonalDiscountEnabled,
    double? seasonalDiscountRate,
    DateTime? seasonalDiscountStart,
    DateTime? seasonalDiscountEnd,
    bool clearSeasonalDiscountStart = false,
    bool clearSeasonalDiscountEnd = false,
  }) {
    return DiscountPolicyModel(
      agent1: agent1 ?? this.agent1,
      agent2: agent2 ?? this.agent2,
      agent1DueDays: agent1DueDays ?? this.agent1DueDays,
      agent2DueDays: agent2DueDays ?? this.agent2DueDays,
      agent1PromotionConfig: agent1PromotionConfig ?? this.agent1PromotionConfig,
      agent2PromotionConfig: agent2PromotionConfig ?? this.agent2PromotionConfig,
      vatPercentage: vatPercentage ?? this.vatPercentage,
      globalAllowVoucherStacking: globalAllowVoucherStacking ?? this.globalAllowVoucherStacking,
      seasonalDiscountEnabled: seasonalDiscountEnabled ?? this.seasonalDiscountEnabled,
      seasonalDiscountRate: seasonalDiscountRate ?? this.seasonalDiscountRate,
      seasonalDiscountStart: clearSeasonalDiscountStart ? null : (seasonalDiscountStart ?? this.seasonalDiscountStart),
      seasonalDiscountEnd: clearSeasonalDiscountEnd ? null : (seasonalDiscountEnd ?? this.seasonalDiscountEnd),
    );
  }

  static DateTime? _parseDateTime(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  factory DiscountPolicyModel.fromJson(Map<String, dynamic> json) {
    return DiscountPolicyModel(
      agent1: AgentPolicy.fromJson(json['agent_1'] ?? {}),
      agent2: AgentPolicy.fromJson(json['agent_2'] ?? {}),
      agent1DueDays: AgentDueDaysPolicy.fromJson(json['agent_1_due_days'] ?? {}),
      agent2DueDays: AgentDueDaysPolicy.fromJson(json['agent_2_due_days'] ?? {}),
      agent1PromotionConfig: AgentPromotionConfig.fromJson(json['agent_1_promotion_config'] ?? {}),
      agent2PromotionConfig: AgentPromotionConfig.fromJson(json['agent_2_promotion_config'] ?? {}),
      vatPercentage: (json['vatPercentage'] as num?)?.toDouble() ?? 10.0,
      globalAllowVoucherStacking: json['globalAllowVoucherStacking'] as bool? ?? false,
      seasonalDiscountEnabled: json['seasonalDiscountEnabled'] as bool? ?? false,
      seasonalDiscountRate: (json['seasonalDiscountRate'] as num?)?.toDouble() ?? 0.05,
      seasonalDiscountStart: _parseDateTime(json['seasonalDiscountStart']),
      seasonalDiscountEnd: _parseDateTime(json['seasonalDiscountEnd']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agent_1': agent1.toJson(),
      'agent_2': agent2.toJson(),
      'agent_1_due_days': agent1DueDays.toJson(),
      'agent_2_due_days': agent2DueDays.toJson(),
      'agent_1_promotion_config': agent1PromotionConfig.toJson(),
      'agent_2_promotion_config': agent2PromotionConfig.toJson(),
      'vatPercentage': vatPercentage,
      'globalAllowVoucherStacking': globalAllowVoucherStacking,
      'seasonalDiscountEnabled': seasonalDiscountEnabled,
      'seasonalDiscountRate': seasonalDiscountRate,
      'seasonalDiscountStart': seasonalDiscountStart != null ? Timestamp.fromDate(seasonalDiscountStart!) : null,
      'seasonalDiscountEnd': seasonalDiscountEnd != null ? Timestamp.fromDate(seasonalDiscountEnd!) : null,
    };
  }

  // Helper để tạo giá trị mặc định nếu DB chưa có
  factory DiscountPolicyModel.defaultPolicy() {
    return DiscountPolicyModel(
      vatPercentage: 10.0,
      globalAllowVoucherStacking: false,
      seasonalDiscountEnabled: false,
      seasonalDiscountRate: 0.05,
      seasonalDiscountStart: DateTime(2026, 5, 1),
      seasonalDiscountEnd: DateTime(2026, 6, 30, 23, 59, 59),
      agent1DueDays: AgentDueDaysPolicy(foliar: 30, root: 30, mixed: 30),
      agent2DueDays: AgentDueDaysPolicy(foliar: 30, root: 30, mixed: 30),
      agent1PromotionConfig: AgentPromotionConfig(allowDiscount: true, allowVoucher: true, allowPromotionDuringCommitment: false),
      agent2PromotionConfig: AgentPromotionConfig(allowDiscount: true, allowVoucher: true, allowPromotionDuringCommitment: false),
      agent1: AgentPolicy(
        foliar: ProductTypePolicy(tiers: [
          DiscountTier(minAmount: 100000000, rate: 0.10),
          DiscountTier(minAmount: 50000000, rate: 0.07),
          DiscountTier(minAmount: 30000000, rate: 0.05),
          DiscountTier(minAmount: 10000000, rate: 0.03),
        ]),
        root: ProductTypePolicy(tiers: [
          DiscountTier(minAmount: 100000000, rate: 0.05),
          DiscountTier(minAmount: 50000000, rate: 0.03),
        ]),
      ),
      agent2: AgentPolicy(
        foliar: ProductTypePolicy(tiers: [
          DiscountTier(minAmount: 50000000, rate: 0.10),
          DiscountTier(minAmount: 30000000, rate: 0.08),
          DiscountTier(minAmount: 10000000, rate: 0.06),
          DiscountTier(minAmount: 3000000, rate: 0.04),
        ]),
        root: ProductTypePolicy(tiers: [
          DiscountTier(minAmount: 50000000, rate: 0.05),
          DiscountTier(minAmount: 30000000, rate: 0.03),
        ]),
      ),
    );
  }
}
