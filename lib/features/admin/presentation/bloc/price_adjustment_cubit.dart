// lib/features/admin/presentation/bloc/price_adjustment_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:piv_app/features/admin/presentation/bloc/price_adjustment_state.dart';

class PriceAdjustmentCubit extends Cubit<PriceAdjustmentState> {
  final AdminRepository _adminRepository;

  PriceAdjustmentCubit({required AdminRepository adminRepository})
      : _adminRepository = adminRepository,
        super(const PriceAdjustmentState());

  Future<void> adjustPrices({
    required String adjustmentType,
    required double adjustmentValue,
    required String productTarget,
    required String agentTarget,
  }) async {
    emit(state.copyWith(status: PriceAdjustmentStatus.loading));

    final result = await _adminRepository.adjustProductPrices(
      adjustmentType: adjustmentType,
      adjustmentValue: adjustmentValue,
      productTarget: productTarget,
      agentTarget: agentTarget,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: PriceAdjustmentStatus.error,
        errorMessage: failure.message,
      )),
      (data) => emit(state.copyWith(
        status: PriceAdjustmentStatus.success,
        successMessage: data['message'] ?? 'Điều chỉnh giá thành công!',
        updatedCount: data['count'] ?? 0,
      )),
    );
  }
}
