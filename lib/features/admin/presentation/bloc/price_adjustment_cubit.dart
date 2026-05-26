// lib/features/admin/presentation/bloc/price_adjustment_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:piv_app/data/models/bulk_price_request_model.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:piv_app/features/admin/domain/repositories/special_price_repository.dart';
import 'package:piv_app/features/admin/presentation/bloc/price_adjustment_state.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';

class PriceAdjustmentCubit extends Cubit<PriceAdjustmentState> {
  final AdminRepository _adminRepository;
  final SpecialPriceRepository _specialPriceRepository;
  final AuthBloc _authBloc;

  PriceAdjustmentCubit({
    required AdminRepository adminRepository,
    required SpecialPriceRepository specialPriceRepository,
    required AuthBloc authBloc,
  })  : _adminRepository = adminRepository,
        _specialPriceRepository = specialPriceRepository,
        _authBloc = authBloc,
        super(const PriceAdjustmentState());

  UserModel? get _currentUser {
    final authState = _authBloc.state;
    if (authState is AuthAuthenticated) return authState.user;
    return null;
  }

  bool get isAdmin => _currentUser?.role == 'admin';

  Future<void> loadAgents() async {
    emit(state.copyWith(isLoadingAgents: true));
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['agent_1', 'agent_2'])
          .where('status', isEqualTo: 'active')
          .get();

      final agents = snapshot.docs
          .map((doc) => UserModel.fromSnap(doc))
          .toList()
        ..sort((a, b) => (a.displayName ?? '').compareTo(b.displayName ?? ''));

      // Nếu là NVKD, lọc đại lý thuộc nhóm của mình
      final currentUser = _currentUser;
      List<UserModel> salesRepGroup = [];
      if (currentUser?.role == 'sales_rep') {
        salesRepGroup = agents
            .where((a) => a.salesRepId == currentUser!.id)
            .toList();
      }

      emit(state.copyWith(
        allAgents: agents,
        salesRepAgents: salesRepGroup,
        isLoadingAgents: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingAgents: false,
        status: PriceAdjustmentStatus.error,
        errorMessage: 'Lỗi tải danh sách đại lý: $e',
      ));
    }
  }

  /// Admin: Áp dụng trực tiếp giá chung
  Future<void> adjustGeneralPrices({
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

  /// Admin: Áp dụng trực tiếp (giá chung hoặc giá riêng hàng loạt)
  Future<void> adjustBulkPrices({
    required String priceType,
    required String adjustmentType,
    required double adjustmentValue,
    required String productTarget,
    required String agentTarget,
    String? salesRepId,
    List<String>? specificAgentIds,
    List<String>? excludedAgentIds,
  }) async {
    emit(state.copyWith(status: PriceAdjustmentStatus.loading));

    // Nếu là giá chung và không có excluded agents → dùng hàm cũ (nhanh hơn)
    if (priceType == 'general' && (excludedAgentIds == null || excludedAgentIds.isEmpty)) {
      final result = await _adminRepository.adjustProductPrices(
        adjustmentType: adjustmentType,
        adjustmentValue: adjustmentValue,
        productTarget: productTarget,
        agentTarget: agentTarget,
      );
      result.fold(
        (failure) => emit(state.copyWith(status: PriceAdjustmentStatus.error, errorMessage: failure.message)),
        (data) => emit(state.copyWith(
          status: PriceAdjustmentStatus.success,
          successMessage: data['message'] ?? 'Điều chỉnh giá chung thành công!',
          updatedCount: data['count'] ?? 0,
        )),
      );
      return;
    }

    // Dùng hàm mới cho tất cả trường hợp khác
    final result = await _adminRepository.adjustBulkPrices(
      priceType: priceType,
      adjustmentType: adjustmentType,
      adjustmentValue: adjustmentValue,
      productTarget: productTarget,
      agentTarget: agentTarget,
      salesRepId: salesRepId,
      specificAgentIds: specificAgentIds,
      excludedAgentIds: excludedAgentIds,
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

  /// Kế toán / NVKD: Tạo yêu cầu chờ duyệt
  Future<void> submitBulkPriceRequest({
    required String priceType,
    required String adjustmentType,
    required double adjustmentValue,
    required String productTarget,
    required String agentTarget,
    String? salesRepId,
    String? salesRepName,
    List<String>? specificAgentIds,
    List<String>? specificAgentNames,
    List<String>? excludedAgentIds,
    List<String>? excludedAgentNames,
  }) async {
    emit(state.copyWith(status: PriceAdjustmentStatus.loading));

    final user = _currentUser;
    if (user == null) {
      emit(state.copyWith(status: PriceAdjustmentStatus.error, errorMessage: 'Chưa đăng nhập'));
      return;
    }

    try {
      final request = BulkPriceRequestModel(
        id: '',
        requesterId: user.id,
        requesterName: user.displayName ?? user.email ?? 'Unknown',
        requesterRole: user.role,
        priceType: priceType,
        adjustmentType: adjustmentType,
        adjustmentValue: adjustmentValue,
        productTarget: productTarget,
        agentTarget: agentTarget,
        salesRepId: salesRepId,
        salesRepName: salesRepName,
        specificAgentIds: specificAgentIds ?? [],
        specificAgentNames: specificAgentNames ?? [],
        excludedAgentIds: excludedAgentIds ?? [],
        excludedAgentNames: excludedAgentNames ?? [],
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _specialPriceRepository.createBulkPriceRequest(request);

      emit(state.copyWith(
        status: PriceAdjustmentStatus.success,
        successMessage: 'Đã gửi yêu cầu điều chỉnh giá. Vui lòng chờ Admin duyệt.',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PriceAdjustmentStatus.error,
        errorMessage: 'Lỗi gửi yêu cầu: $e',
      ));
    }
  }
}
