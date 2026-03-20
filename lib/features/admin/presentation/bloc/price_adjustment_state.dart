// lib/features/admin/presentation/bloc/price_adjustment_state.dart

import 'package:equatable/equatable.dart';

enum PriceAdjustmentStatus { initial, loading, success, error }

class PriceAdjustmentState extends Equatable {
  final PriceAdjustmentStatus status;
  final String? errorMessage;
  final String? successMessage;
  final int updatedCount;

  const PriceAdjustmentState({
    this.status = PriceAdjustmentStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.updatedCount = 0,
  });

  PriceAdjustmentState copyWith({
    PriceAdjustmentStatus? status,
    String? errorMessage,
    String? successMessage,
    int? updatedCount,
  }) {
    return PriceAdjustmentState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
      updatedCount: updatedCount ?? this.updatedCount,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, successMessage, updatedCount];
}
