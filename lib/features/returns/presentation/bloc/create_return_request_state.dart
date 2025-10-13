part of 'create_return_request_cubit.dart';

class CreateReturnRequestState extends Equatable {
  final CreateReturnRequestStatus status;
  final List<OrderItemModel> selectedItems;
  final List<File> images;
  final String? errorMessage;

  const CreateReturnRequestState({
    this.status = CreateReturnRequestStatus.initial,
    this.selectedItems = const [],
    this.images = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, selectedItems, images, errorMessage];

  CreateReturnRequestState copyWith({
    CreateReturnRequestStatus? status,
    List<OrderItemModel>? selectedItems,
    List<File>? images,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CreateReturnRequestState(
      status: status ?? this.status,
      selectedItems: selectedItems ?? this.selectedItems,
      images: images ?? this.images,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

enum CreateReturnRequestStatus { initial, loading, success, error, submitting }