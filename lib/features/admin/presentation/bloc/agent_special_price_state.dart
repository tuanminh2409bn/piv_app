import 'package:equatable/equatable.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';

enum AgentSpecialPriceStatus { initial, loading, success, error, saving }

class AgentSpecialPriceState extends Equatable {
  final AgentSpecialPriceStatus status;
  final List<ProductModel> products;
  final Map<String, double> specialPrices;
  final bool useGeneralPrice;
  final String? errorMessage;

  const AgentSpecialPriceState({
    this.status = AgentSpecialPriceStatus.initial,
    this.products = const [],
    this.specialPrices = const {},
    this.useGeneralPrice = true,
    this.errorMessage,
  });

  AgentSpecialPriceState copyWith({
    AgentSpecialPriceStatus? status,
    List<ProductModel>? products,
    Map<String, double>? specialPrices,
    bool? useGeneralPrice,
    String? errorMessage,
  }) {
    return AgentSpecialPriceState(
      status: status ?? this.status,
      products: products ?? this.products,
      specialPrices: specialPrices ?? this.specialPrices,
      useGeneralPrice: useGeneralPrice ?? this.useGeneralPrice,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, products, specialPrices, useGeneralPrice, errorMessage];
}
