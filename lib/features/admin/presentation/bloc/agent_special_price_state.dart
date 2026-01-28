import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/price_request_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';

enum AgentSpecialPriceStatus { initial, loading, success, error, saving }

class AgentSpecialPriceState extends Equatable {
  final AgentSpecialPriceStatus status;
  final List<ProductModel> products;
  final Map<String, double> specialPrices; // Giá thực tế trên DB
  final Map<String, double> unsavedChanges; // Giá đang sửa (local)
  final bool useGeneralPrice;
  final String? errorMessage;
  final PriceRequestModel? pendingRequest; // Yêu cầu đang chờ duyệt

  const AgentSpecialPriceState({
    this.status = AgentSpecialPriceStatus.initial,
    this.products = const [],
    this.specialPrices = const {},
    this.unsavedChanges = const {},
    this.useGeneralPrice = true,
    this.errorMessage,
    this.pendingRequest,
  });

  bool get isLocked => pendingRequest != null; // UI helper

  AgentSpecialPriceState copyWith({
    AgentSpecialPriceStatus? status,
    List<ProductModel>? products,
    Map<String, double>? specialPrices,
    Map<String, double>? unsavedChanges,
    bool? useGeneralPrice,
    String? errorMessage,
    PriceRequestModel? pendingRequest,
    bool clearPendingRequest = false,
  }) {
    return AgentSpecialPriceState(
      status: status ?? this.status,
      products: products ?? this.products,
      specialPrices: specialPrices ?? this.specialPrices,
      unsavedChanges: unsavedChanges ?? this.unsavedChanges,
      useGeneralPrice: useGeneralPrice ?? this.useGeneralPrice,
      errorMessage: errorMessage,
      pendingRequest: clearPendingRequest ? null : (pendingRequest ?? this.pendingRequest),
    );
  }

  @override
  List<Object?> get props =>
      [status, products, specialPrices, unsavedChanges, useGeneralPrice, errorMessage, pendingRequest];
}
