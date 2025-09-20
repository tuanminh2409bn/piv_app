// lib/features/admin/presentation/bloc/manage_quick_list_cubit.dart

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/admin/data/models/quick_order_item_model.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';

part 'manage_quick_list_state.dart';

class ManageQuickListCubit extends Cubit<ManageQuickListState> {
  final AdminRepository _adminRepository;
  final String _agentId;
  StreamSubscription? _quickListSubscription;

  ManageQuickListCubit({
    required AdminRepository adminRepository,
    required String agentId,
  })  : _adminRepository = adminRepository,
        _agentId = agentId,
        super(const ManageQuickListState()) {
    _subscribeToQuickList();
  }

  void _subscribeToQuickList() {
    _quickListSubscription?.cancel();
    _quickListSubscription = _adminRepository.getQuickOrderItems(_agentId).listen((items) async {
      emit(state.copyWith(status: ManageQuickListStatus.loading));
      try {
        if (items.isEmpty) {
          emit(state.copyWith(
            status: ManageQuickListStatus.success,
            quickOrderItems: [],
            products: [],
          ));
          return;
        }

        final productIds = items.map((item) => item.productId).toList();
        // Lấy thông tin chi tiết sản phẩm từ các ID có được
        final products = await _adminRepository.getProductsByIds(productIds);

        emit(state.copyWith(
          status: ManageQuickListStatus.success,
          quickOrderItems: items,
          products: products,
        ));
      } catch (e) {
        emit(state.copyWith(
            status: ManageQuickListStatus.error, errorMessage: e.toString()));
      }
    });
  }

  Future<void> addProduct(String productId, String currentUserId) async {
    try {
      await _adminRepository.addProductToQuickList(
        agentId: _agentId,
        productId: productId,
        addedBy: currentUserId,
      );
      // Dữ liệu sẽ tự động cập nhật nhờ Stream, không cần emit state ở đây
    } catch (e) {
      emit(state.copyWith(status: ManageQuickListStatus.error, errorMessage: 'Thêm sản phẩm thất bại: $e'));
      // Quay lại trạng thái success để không hiển thị lỗi mãi
      emit(state.copyWith(status: ManageQuickListStatus.success));
    }
  }

  Future<void> removeProduct(String productId) async {
    try {
      // Tìm itemId tương ứng với productId để xóa
      final itemToRemove = state.quickOrderItems.firstWhere((item) => item.productId == productId);
      await _adminRepository.removeProductFromQuickList(
        agentId: _agentId,
        itemId: itemToRemove.id,
      );
      // Dữ liệu sẽ tự động cập nhật nhờ Stream
    } catch (e) {
      emit(state.copyWith(status: ManageQuickListStatus.error, errorMessage: 'Xóa sản phẩm thất bại: $e'));
      emit(state.copyWith(status: ManageQuickListStatus.success));
    }
  }

  @override
  Future<void> close() {
    _quickListSubscription?.cancel();
    return super.close();
  }
}