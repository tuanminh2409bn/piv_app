import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/data/models/price_request_model.dart';
import 'package:piv_app/features/admin/domain/repositories/special_price_repository.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';

part 'price_approval_state.dart';

class PriceApprovalCubit extends Cubit<PriceApprovalState> {
  final SpecialPriceRepository _repository;
  final AuthBloc _authBloc;
  StreamSubscription? _subscription;

  PriceApprovalCubit({
    required SpecialPriceRepository repository,
    required AuthBloc authBloc,
  })  : _repository = repository,
        _authBloc = authBloc,
        super(const PriceApprovalState()) {
    _watchRequests();
  }

  void _watchRequests() {
    emit(state.copyWith(status: PriceApprovalStatus.loading));
    _subscription = _repository.watchPendingRequests().listen(
      (requests) {
        emit(state.copyWith(
          status: PriceApprovalStatus.success,
          pendingRequests: requests,
        ));
      },
      onError: (error) {
        emit(state.copyWith(
          status: PriceApprovalStatus.error,
          errorMessage: error.toString(),
        ));
      },
    );
  }

  Future<void> approveRequest(PriceRequestModel request) async {
    try {
      final currentUser = (_authBloc.state as AuthAuthenticated).user;
      await _repository.approveRequest(request, currentUser.id);
      // Success is handled by stream update (item removed from list)
    } catch (e) {
      emit(state.copyWith(
        status: PriceApprovalStatus.error,
        errorMessage: 'Lỗi khi duyệt: $e',
      ));
    }
  }

  Future<void> rejectRequest(String requestId, String reason) async {
    try {
      await _repository.rejectRequest(requestId, reason);
    } catch (e) {
      emit(state.copyWith(
        status: PriceApprovalStatus.error,
        errorMessage: 'Lỗi khi từ chối: $e',
      ));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
