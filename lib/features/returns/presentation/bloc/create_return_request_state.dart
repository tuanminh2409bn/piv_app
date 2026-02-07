// lib/features/returns/presentation/bloc/create_return_request_state.dart
part of 'create_return_request_cubit.dart';

// Sử dụng enum status chính xác của bạn
enum CreateReturnRequestStatus { initial, loading, success, error, submitting }

class CreateReturnRequestState extends Equatable {
  // --- THAY ĐỔI CỐT LÕI NẰM Ở ĐÂY ---
  final Map<String, int> returnedItems; // Key: productId, Value: số lượng chai/gói trả
  final List<File> images;
  final CreateReturnRequestStatus status;
  final String? errorMessage;
  final ReturnPolicyConfigModel? policy;

  const CreateReturnRequestState({
    this.returnedItems = const {},
    this.images = const [],
    this.status = CreateReturnRequestStatus.initial,
    this.errorMessage,
    this.policy,
  });

  @override
  List<Object?> get props => [returnedItems, images, status, errorMessage, policy];

  CreateReturnRequestState copyWith({
    Map<String, int>? returnedItems,
    List<File>? images,
    CreateReturnRequestStatus? status,
    String? errorMessage,
    bool clearError = false,
    ReturnPolicyConfigModel? policy,
  }) {
    return CreateReturnRequestState(
      returnedItems: returnedItems ?? this.returnedItems,
      images: images ?? this.images,
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      policy: policy ?? this.policy,
    );
  }
}