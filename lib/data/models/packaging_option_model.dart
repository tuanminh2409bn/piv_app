// lib/data/models/packaging_option_model.dart

import 'package:equatable/equatable.dart';

class PackagingOptionModel extends Equatable {
  final String name;
  final int quantityPerPackage;
  final String unit;
  final Map<String, double> prices;

  const PackagingOptionModel({
    required this.name,
    required this.quantityPerPackage,
    required this.unit,
    required this.prices,
  });

  @override
  List<Object?> get props => [name, quantityPerPackage, unit, prices];

  double getPriceForRole(String role) => prices[role] ?? 0.0;

  factory PackagingOptionModel.fromMap(Map<String, dynamic> map) {
    Map<String, double> pricesMap = {};
    if (map['prices'] is Map) {
      (map['prices'] as Map).forEach((key, value) {
        if (value is num) pricesMap[key] = value.toDouble();
      });
    }
    return PackagingOptionModel(
      name: map['name'] as String? ?? 'N/A',
      quantityPerPackage: (map['quantityPerPackage'] as num? ?? 1).toInt(),
      unit: map['unit'] as String? ?? 'sản phẩm',
      prices: pricesMap,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantityPerPackage': quantityPerPackage,
      'unit': unit,
      'prices': prices,
    };
  }

  PackagingOptionModel copyWith({
    String? name,
    int? quantityPerPackage,
    String? unit,
    Map<String, double>? prices,
    double? priceAgent1,
    double? priceAgent2,
    double? retailPrice,
  }) {
    final updatedPrices = Map<String, double>.from(prices ?? this.prices);

    if (priceAgent1 != null) updatedPrices['agent_1'] = priceAgent1;
    if (priceAgent2 != null) updatedPrices['agent_2'] = priceAgent2;
    if (retailPrice != null) updatedPrices['guest'] = retailPrice;

    return PackagingOptionModel(
      name: name ?? this.name,
      quantityPerPackage: quantityPerPackage ?? this.quantityPerPackage,
      unit: unit ?? this.unit,
      prices: updatedPrices,
    );
  }
}