//lib/features/returns/presentation/bloc/create_return_request_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:piv_app/data/models/order_item_model.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/data/models/return_policy_config_model.dart';
import 'package:piv_app/features/returns/domain/entities/return_request_item.dart';
import 'package:piv_app/features/returns/domain/repositories/return_repository.dart';
import 'package:piv_app/features/returns/domain/repositories/return_settings_repository.dart';

part 'create_return_request_state.dart';

class CreateReturnRequestCubit extends Cubit<CreateReturnRequestState> {
  final ReturnRepository _returnRepository;
  final ReturnSettingsRepository _settingsRepository;

  CreateReturnRequestCubit({
    required ReturnRepository returnRepository,
    required ReturnSettingsRepository settingsRepository,
  })  : _returnRepository = returnRepository,
        _settingsRepository = settingsRepository,
        super(const CreateReturnRequestState());

  Future<void> loadPolicy() async {
    try {
      final policy = await _settingsRepository.getReturnPolicy();
      emit(state.copyWith(policy: policy));
    } catch (e) {
      // Keep default policy or handle error
      emit(state.copyWith(errorMessage: 'Không thể tải chính sách đổi trả: $e'));
    }
  }

  void updateReturnQuantity(OrderItemModel item, int newQuantity) {
    final currentItems = Map<String, int>.from(state.returnedItems);
    final maxQuantity = item.quantity * item.quantityPerPackage;

    if (newQuantity < 0) newQuantity = 0;
    if (newQuantity > maxQuantity) newQuantity = maxQuantity;

    if (newQuantity == 0) {
      currentItems.remove(item.productId);
    } else {
      currentItems[item.productId] = newQuantity;
    }
    emit(state.copyWith(returnedItems: currentItems));
  }

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 80);
    if (pickedFiles.isNotEmpty) {
      emit(state.copyWith(images: [...state.images, ...pickedFiles]));
    }
  }

  void removeImage(XFile image) {
    final currentImages = List<XFile>.from(state.images);
    currentImages.remove(image);
    emit(state.copyWith(images: currentImages));
  }

  Future<void> submitRequest({
    required OrderModel order,
    required String reason,
    required String userNotes,
    required double penaltyFee,
    required double refundAmount,
  }) async {
    if (state.returnedItems.isEmpty || state.returnedItems.values.every((qty) => qty == 0)) {
      emit(state.copyWith(status: CreateReturnRequestStatus.error, errorMessage: 'Vui lòng chọn số lượng cần trả cho ít nhất một sản phẩm.'));
      emit(state.copyWith(status: CreateReturnRequestStatus.initial, clearError: true));
      return;
    }
    if (state.images.isEmpty) {
      emit(state.copyWith(status: CreateReturnRequestStatus.error, errorMessage: 'Vui lòng cung cấp ít nhất một hình ảnh làm bằng chứng.'));
      emit(state.copyWith(status: CreateReturnRequestStatus.initial, clearError: true));
      return;
    }

    emit(state.copyWith(status: CreateReturnRequestStatus.submitting));

    final List<ReturnRequestItem> returnItems = [];
    state.returnedItems.forEach((productId, returnedQuantity) {
      if (returnedQuantity > 0) {
        final originalItem = order.items.firstWhere((item) => item.productId == productId);
        returnItems.add(
          ReturnRequestItem(
            productId: productId,
            productName: originalItem.productName,
            returnedQuantity: returnedQuantity,
            itemUnit: originalItem.unit,
            reason: reason,
          ),
        );
      }
    });

    final result = await _returnRepository.createReturnRequest(
      order: order,
      items: returnItems,
      images: state.images,
      userNotes: userNotes,
      penaltyFee: penaltyFee,
      refundAmount: refundAmount,
    );

    result.fold(
          (failure) => emit(state.copyWith(status: CreateReturnRequestStatus.error, errorMessage: failure.message)),
          (_) => emit(state.copyWith(status: CreateReturnRequestStatus.success)),
    );
  }
}
