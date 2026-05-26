// lib/features/admin/presentation/bloc/price_adjustment_state.dart

import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/user_model.dart';

enum PriceAdjustmentStatus { initial, loading, loadingAgents, success, error }

class PriceAdjustmentState extends Equatable {
  final PriceAdjustmentStatus status;
  final String? errorMessage;
  final String? successMessage;
  final int updatedCount;
  final List<UserModel> allAgents;
  final List<UserModel> salesRepAgents; // Đại lý thuộc NVKD hiện tại
  final bool isLoadingAgents;

  const PriceAdjustmentState({
    this.status = PriceAdjustmentStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.updatedCount = 0,
    this.allAgents = const [],
    this.salesRepAgents = const [],
    this.isLoadingAgents = false,
  });

  PriceAdjustmentState copyWith({
    PriceAdjustmentStatus? status,
    String? errorMessage,
    String? successMessage,
    int? updatedCount,
    List<UserModel>? allAgents,
    List<UserModel>? salesRepAgents,
    bool? isLoadingAgents,
  }) {
    return PriceAdjustmentState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
      updatedCount: updatedCount ?? this.updatedCount,
      allAgents: allAgents ?? this.allAgents,
      salesRepAgents: salesRepAgents ?? this.salesRepAgents,
      isLoadingAgents: isLoadingAgents ?? this.isLoadingAgents,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, successMessage, updatedCount, allAgents, salesRepAgents, isLoadingAgents];
}
