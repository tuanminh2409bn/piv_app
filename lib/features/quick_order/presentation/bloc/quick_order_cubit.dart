// lib/features/quick_order/presentation/bloc/quick_order_cubit.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/quick_order/domain/repositories/quick_order_repository.dart';

part 'quick_order_state.dart';

class QuickOrderCubit extends Cubit<QuickOrderState> {
  final QuickOrderRepository _quickOrderRepository;
  final AuthBloc _authBloc;
  StreamSubscription? _quickListSubscription;
  late final String _agentId;

  QuickOrderCubit({
    required QuickOrderRepository quickOrderRepository,
    required AuthBloc authBloc,
  })  : _quickOrderRepository = quickOrderRepository,
        _authBloc = authBloc,
        super(const QuickOrderState()) {
    final authState = _authBloc.state;
    if (authState is AuthAuthenticated) {
      _agentId = authState.user.id;
      _subscribeToQuickList();
    } else {
      emit(state.copyWith(
          status: QuickOrderStatus.error,
          errorMessage: 'Không thể xác thực người dùng.'));
    }
  }

  void _subscribeToQuickList() {
    emit(state.copyWith(status: QuickOrderStatus.loading));
    _quickListSubscription?.cancel();
    _quickListSubscription =
        _quickOrderRepository.getQuickOrderItems(_agentId).listen((items) async {
          try {
            if (items.isEmpty) {
              emit(state.copyWith(
                status: QuickOrderStatus.success,
                products: [],
              ));
              return;
            }

            final productIds = items.map((item) => item.productId).toList();
            final products = await _quickOrderRepository.getProductsByIds(productIds);

            emit(state.copyWith(
              status: QuickOrderStatus.success,
              products: products,
            ));
          } catch (e) {
            emit(state.copyWith(
                status: QuickOrderStatus.error, errorMessage: e.toString()));
          }
        });
  }

  @override
  Future<void> close() {
    _quickListSubscription?.cancel();
    return super.close();
  }
}