// lib/features/admin/presentation/bloc/bulk_price_requests_cubit.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/bulk_price_request_model.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:piv_app/features/admin/domain/repositories/special_price_repository.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';

// --- STATE ---
enum BulkPriceRequestsStatus { initial, loading, success, error }

class BulkPriceRequestsState extends Equatable {
  final BulkPriceRequestsStatus status;
  final List<BulkPriceRequestModel> requests;
  final String? errorMessage;
  final String? successMessage;

  const BulkPriceRequestsState({
    this.status = BulkPriceRequestsStatus.initial,
    this.requests = const [],
    this.errorMessage,
    this.successMessage,
  });

  BulkPriceRequestsState copyWith({
    BulkPriceRequestsStatus? status,
    List<BulkPriceRequestModel>? requests,
    String? errorMessage,
    String? successMessage,
  }) {
    return BulkPriceRequestsState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [status, requests, errorMessage, successMessage];
}

// --- CUBIT ---
class BulkPriceRequestsCubit extends Cubit<BulkPriceRequestsState> {
  final SpecialPriceRepository _specialPriceRepository;
  final AdminRepository _adminRepository;
  final AuthBloc _authBloc;
  StreamSubscription? _subscription;

  BulkPriceRequestsCubit({
    required SpecialPriceRepository specialPriceRepository,
    required AdminRepository adminRepository,
    required AuthBloc authBloc,
  })  : _specialPriceRepository = specialPriceRepository,
        _adminRepository = adminRepository,
        _authBloc = authBloc,
        super(const BulkPriceRequestsState());

  void watchPendingRequests() {
    emit(state.copyWith(status: BulkPriceRequestsStatus.loading));
    _subscription?.cancel();
    _subscription = _specialPriceRepository.watchPendingBulkRequests().listen(
      (requests) {
        if (!isClosed) {
          emit(state.copyWith(
            status: BulkPriceRequestsStatus.success,
            requests: requests,
          ));
        }
      },
      onError: (e) {
        if (!isClosed) {
          emit(state.copyWith(
            status: BulkPriceRequestsStatus.error,
            errorMessage: 'Lỗi tải yêu cầu: $e',
          ));
        }
      },
    );
  }

  Future<void> approveRequest(BulkPriceRequestModel request) async {
    emit(state.copyWith(status: BulkPriceRequestsStatus.loading));
    try {
      final authState = _authBloc.state;
      if (authState is! AuthAuthenticated) return;
      final adminId = authState.user.id;
      final adminName = authState.user.displayName ?? authState.user.email ?? 'Admin';

      // 1. Mark as approved in Firestore
      await _specialPriceRepository.approveBulkRequest(request.id, adminId, adminName);

      // 2. Execute the bulk price adjustment via Cloud Function
      await _adminRepository.adjustBulkPrices(
        priceType: request.priceType,
        adjustmentType: request.adjustmentType,
        adjustmentValue: request.adjustmentValue,
        productTarget: request.productTarget,
        agentTarget: request.agentTarget,
        salesRepId: request.salesRepId,
        specificAgentIds: request.specificAgentIds.isNotEmpty ? request.specificAgentIds : null,
        excludedAgentIds: request.excludedAgentIds.isNotEmpty ? request.excludedAgentIds : null,
      );

      emit(state.copyWith(
        status: BulkPriceRequestsStatus.success,
        successMessage: 'Đã duyệt và áp dụng điều chỉnh giá thành công!',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BulkPriceRequestsStatus.error,
        errorMessage: 'Lỗi duyệt yêu cầu: $e',
      ));
    }
  }

  Future<void> rejectRequest(String requestId, String reason) async {
    try {
      await _specialPriceRepository.rejectBulkRequest(requestId, reason);
      emit(state.copyWith(
        status: BulkPriceRequestsStatus.success,
        successMessage: 'Đã từ chối yêu cầu.',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BulkPriceRequestsStatus.error,
        errorMessage: 'Lỗi từ chối: $e',
      ));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
