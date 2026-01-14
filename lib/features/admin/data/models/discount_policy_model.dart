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

class DiscountPolicyModel {
  final AgentPolicy agent1;
  final AgentPolicy agent2;

  DiscountPolicyModel({required this.agent1, required this.agent2});

  factory DiscountPolicyModel.fromJson(Map<String, dynamic> json) {
    return DiscountPolicyModel(
      agent1: AgentPolicy.fromJson(json['agent_1'] ?? {}),
      agent2: AgentPolicy.fromJson(json['agent_2'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agent_1': agent1.toJson(),
      'agent_2': agent2.toJson(),
    };
  }
  
  // Helper để tạo giá trị mặc định nếu DB chưa có
  factory DiscountPolicyModel.defaultPolicy() {
    return DiscountPolicyModel(
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
