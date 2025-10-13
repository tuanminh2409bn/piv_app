part of 'admin_categories_cubit.dart';

enum AdminCategoriesStatus { initial, loading, success, error }

class AdminCategoriesState extends Equatable {
  final AdminCategoriesStatus status;
  // Lưu trữ tất cả các danh mục dưới dạng một danh sách phẳng
  final List<CategoryModel> allCategories;
  final String? errorMessage;

  const AdminCategoriesState({
    this.status = AdminCategoriesStatus.initial,
    this.allCategories = const [],
    this.errorMessage,
  });

  // Getter tiện ích để lấy ra các danh mục gốc (cấp 1)
  List<CategoryModel> get topLevelCategories =>
      allCategories.where((c) => c.parentId == null).toList();

  // Hàm tiện ích để lấy các danh mục con của một danh mục cha cụ thể
  List<CategoryModel> getSubCategoriesFor(String parentId) {
    return allCategories.where((c) => c.parentId == parentId).toList();
  }

  @override
  List<Object?> get props => [status, allCategories, errorMessage];

  AdminCategoriesState copyWith({
    AdminCategoriesStatus? status,
    List<CategoryModel>? allCategories,
    String? errorMessage,
  }) {
    return AdminCategoriesState(
      status: status ?? this.status,
      allCategories: allCategories ?? this.allCategories,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
