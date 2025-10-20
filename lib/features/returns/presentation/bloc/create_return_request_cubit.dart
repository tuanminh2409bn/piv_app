//lib/features/returns/domain/entities/create_return_request_cubit.dart

import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:piv_app/data/models/order_item_model.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/features/returns/domain/entities/return_request_item.dart';
import 'package:piv_app/features/returns/domain/repositories/return_repository.dart';

part 'create_return_request_state.dart';

class CreateReturnRequestCubit extends Cubit<CreateReturnRequestState> {
  final ReturnRepository _returnRepository;

  CreateReturnRequestCubit({required ReturnRepository returnRepository})
      : _returnRepository = returnRepository,
        super(const CreateReturnRequestState());

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
      final newImages = pickedFiles.map((file) => File(file.path)).toList();
      emit(state.copyWith(images: [...state.images, ...newImages]));
    }
  }

  void removeImage(File image) {
    final currentImages = List<File>.from(state.images);
    currentImages.remove(image);
    emit(state.copyWith(images: currentImages));
  }

  Future<void> submitRequest({
    required OrderModel order,
    required String reason,
    required String userNotes,
    required double penaltyFee,
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
    );

    result.fold(
          (failure) => emit(state.copyWith(status: CreateReturnRequestStatus.error, errorMessage: failure.message)),
          (_) => emit(state.copyWith(status: CreateReturnRequestStatus.success)),
    );
  }
}