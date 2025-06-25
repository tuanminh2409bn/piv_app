import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/commission_model.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';

part 'admin_commissions_state.dart';

class AdminCommissionsCubit extends Cubit<AdminCommissionsState> {
  final OrderRepository _orderRepository;
  final AuthBloc _authBloc;

  AdminCommissionsCubit({
    required OrderRepository orderRepository,
    required AuthBloc authBloc,
  })  : _orderRepository = orderRepository,
        _authBloc = authBloc,
        super(const AdminCommissionsState());

  Future<void> fetchAllCommissions() async {
    emit(state.copyWith(status: AdminCommissionsStatus.loading));
    final result = await _orderRepository.getAllCommissions();
    result.fold(
          (failure) => emit(state.copyWith(status: AdminCommissionsStatus.error, errorMessage: failure.message)),
          (commissions) {
        emit(state.copyWith(
          status: AdminCommissionsStatus.success,
          allCommissions: commissions,
        ));
        filterCommissions(state.currentFilter);
      },
    );
  }

  void filterCommissions(String filter) {
    List<CommissionModel> filtered;
    if (filter == 'all') {
      filtered = state.allCommissions;
    } else {
      filtered = state.allCommissions.where((c) => c.statusString == filter).toList();
    }
    emit(state.copyWith(filteredCommissions: filtered, currentFilter: filter));
  }

  Future<void> markAsPaid(String commissionId) async {
    final authState = _authBloc.state;
    if (authState is! AuthAuthenticated) return;

    final accountantId = authState.user.id;
    final result = await _orderRepository.updateCommissionStatus(commissionId, 'paid', accountantId);
    if (result.isRight()) {
      fetchAllCommissions();
    } else {
      result.leftMap((failure) => emit(state.copyWith(status: AdminCommissionsStatus.error, errorMessage: failure.message)));
    }
  }
}