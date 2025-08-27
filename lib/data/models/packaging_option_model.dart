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
}