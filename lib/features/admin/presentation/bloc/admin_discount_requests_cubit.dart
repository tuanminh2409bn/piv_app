import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/admin/data/models/discount_request_model.dart';
import 'package:piv_app/features/admin/domain/repositories/discount_repository.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';

part 'admin_discount_requests_state.dart';

class AdminDiscountRequestsCubit extends Cubit<AdminDiscountRequestsState> {
  final DiscountRepository _repository;
  final AuthBloc _authBloc;

  AdminDiscountRequestsCubit({
    required DiscountRepository repository,
    required AuthBloc authBloc,
  })  : _repository = repository,
        _authBloc = authBloc,
        super(const AdminDiscountRequestsState()) {
    _watchRequests();
  }

  void _watchRequests() {
    _repository.watchPendingRequests().listen((requests) {
      emit(state.copyWith(requests: requests, status: AdminDiscountRequestsStatus.loaded));
    });
  }

  Future<void> approveRequest(DiscountRequestModel request, {Map<String, dynamic>? modifiedConfig}) async {
    final authState = _authBloc.state;
    if (authState is! AuthAuthenticated) return;

    try {
      await _repository.approveRequest(request, authState.user.id, modifiedDiscountConfig: modifiedConfig);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> rejectRequest(String requestId, String reason) async {
    try {
      await _repository.rejectRequest(requestId, reason);
    } catch (e) {
      // Handle error
    }
  }
}
