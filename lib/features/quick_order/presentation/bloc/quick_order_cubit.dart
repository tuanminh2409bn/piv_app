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
    String? targetAgentId,
  })  : _quickOrderRepository = quickOrderRepository,
        _authBloc = authBloc,
        super(const QuickOrderState()) {
    
    if (targetAgentId != null) {
      _agentId = targetAgentId;
      _subscribeToQuickList();
    } else {
      // Tự động kiểm tra auth hiện tại
      _checkAuthAndSubscribe();

      // Lắng nghe thay đổi Auth để tự động cập nhật nếu đăng nhập sau khi vào app
      _authBlocSubscription = _authBloc.stream.listen((authState) {
        if (authState is AuthAuthenticated) {
          _agentId = authState.user.id;
          _subscribeToQuickList();
        }
      });
    }
  }

  StreamSubscription? _authBlocSubscription;

  void _checkAuthAndSubscribe() {
    final authState = _authBloc.state;
    if (authState is AuthAuthenticated) {
      _agentId = authState.user.id;
      _subscribeToQuickList();
    } else {
      emit(state.copyWith(
          status: QuickOrderStatus.error,
          errorMessage: 'Vui lòng đăng nhập để sử dụng tính năng này.'));
    }
  }

  void _subscribeToQuickList() {
    emit(state.copyWith(status: QuickOrderStatus.loading));
    _quickListSubscription?.cancel();

    // Lấy danh sách item của _agentId (Đã đúng logic trên)
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

            // --- 3. QUAN TRỌNG: Cần truyền _agentId vào đây để lấy Private Product ---
            // Lưu ý: Bạn cần đảm bảo QuickOrderRepository.getProductsByIds
            // cũng đã được cập nhật để nhận tham số `currentUserId` giống HomeRepository.
            final products = await _quickOrderRepository.getProductsByIds(
                productIds,
                currentUserId: _agentId // <-- SỬA: Truyền ID để lọc sản phẩm private
            );
            // -------------------------------------------------------------------------

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
    _authBlocSubscription?.cancel();
    return super.close();
  }
}