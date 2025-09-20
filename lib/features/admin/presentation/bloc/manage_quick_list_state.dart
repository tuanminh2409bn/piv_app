// lib/features/admin/presentation/bloc/manage_quick_list_state.dart

part of 'manage_quick_list_cubit.dart';

enum ManageQuickListStatus { initial, loading, success, error }

class ManageQuickListState extends Equatable {
  final ManageQuickListStatus status;
  // Danh sách các sản phẩm đầy đủ thông tin để hiển thị
  final List<ProductModel> products;
  // Danh sách các item gốc từ Firestore (chứa ID để xóa)
  final List<QuickOrderItemModel> quickOrderItems;
  final String? errorMessage;

  const ManageQuickListState({
    this.status = ManageQuickListStatus.initial,
    this.products = const [],
    this.quickOrderItems = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, products, quickOrderItems, errorMessage];

  ManageQuickListState copyWith({
    ManageQuickListStatus? status,
    List<ProductModel>? products,
    List<QuickOrderItemModel>? quickOrderItems,
    String? errorMessage,
  }) {
    return ManageQuickListState(
      status: status ?? this.status,
      products: products ?? this.products,
      quickOrderItems: quickOrderItems ?? this.quickOrderItems,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}