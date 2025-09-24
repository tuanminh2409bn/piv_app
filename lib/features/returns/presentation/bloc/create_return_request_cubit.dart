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

  void toggleItemSelection(OrderItemModel item) {
    final currentSelection = List<OrderItemModel>.from(state.selectedItems);
    if (currentSelection.contains(item)) {
      currentSelection.remove(item);
    } else {
      currentSelection.add(item);
    }
    emit(state.copyWith(selectedItems: currentSelection));
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
    required String reason, // Giả sử lý do chung cho tất cả sản phẩm
    required String userNotes,
  }) async {
    if (state.selectedItems.isEmpty) {
      emit(state.copyWith(status: CreateReturnRequestStatus.error, errorMessage: 'Vui lòng chọn ít nhất một sản phẩm.'));
      return;
    }
    if (state.images.isEmpty) {
      emit(state.copyWith(status: CreateReturnRequestStatus.error, errorMessage: 'Vui lòng cung cấp ít nhất một hình ảnh làm bằng chứng.'));
      return;
    }

    emit(state.copyWith(status: CreateReturnRequestStatus.submitting));

    final returnItems = state.selectedItems
        .map((item) => ReturnRequestItem(
      productId: item.productId,
      productName: item.productName,
      quantity: item.quantity,
      reason: reason,
    ))
        .toList();

    final result = await _returnRepository.createReturnRequest(
      order: order,
      items: returnItems,
      images: state.images,
      userNotes: userNotes,
    );

    result.fold(
          (failure) => emit(state.copyWith(status: CreateReturnRequestStatus.error, errorMessage: failure.message)),
          (_) => emit(state.copyWith(status: CreateReturnRequestStatus.success)),
    );
  }
}