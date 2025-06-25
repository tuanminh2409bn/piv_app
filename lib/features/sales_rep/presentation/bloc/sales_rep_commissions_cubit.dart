import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/data/models/commission_model.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/orders/domain/repositories/order_repository.dart';

part 'sales_rep_commissions_state.dart';

class SalesRepCommissionsCubit extends Cubit<SalesRepCommissionsState> {
  final OrderRepository _orderRepository;
  final AuthBloc _authBloc;

  SalesRepCommissionsCubit({
    required OrderRepository orderRepository,
    required AuthBloc authBloc,
  })  : _orderRepository = orderRepository,
        _authBloc = authBloc,
        super(const SalesRepCommissionsState());

  Future<void> fetchMyCommissions() async {
    final authState = _authBloc.state;
    if (authState is! AuthAuthenticated || !authState.user.isSalesRep) {
      return;
    }

    final salesRepId = authState.user.id;
    emit(state.copyWith(status: SalesRepCommissionsStatus.loading));

    final result = await _orderRepository.getCommissionsBySalesRepId(salesRepId);
    result.fold(
          (failure) => emit(state.copyWith(status: SalesRepCommissionsStatus.error, errorMessage: failure.message)),
          (commissions) => emit(state.copyWith(status: SalesRepCommissionsStatus.success, commissions: commissions)),
    );
  }
}