import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/home/data/models/category_model.dart';
import 'package:piv_app/features/home/domain/repositories/home_repository.dart';

part 'admin_categories_state.dart';

class AdminCategoriesCubit extends Cubit<AdminCategoriesState> {
  final HomeRepository _homeRepository;

  AdminCategoriesCubit({required HomeRepository homeRepository})
      : _homeRepository = homeRepository,
        super(const AdminCategoriesState());

  Future<void> fetchAllCategories() async {
    emit(state.copyWith(status: AdminCategoriesStatus.loading));
    final result = await _homeRepository.getAllCategories();
    result.fold(
          (failure) => emit(state.copyWith(status: AdminCategoriesStatus.error, errorMessage: failure.message)),
          (categories) => emit(state.copyWith(status: AdminCategoriesStatus.success, allCategories: categories)),
    );
  }

  Future<void> saveCategory({
    CategoryModel? existingCategory,
    required String name,
    required String imageUrl,
    String? parentId,
  }) async {
    final categoryToSave = existingCategory != null
        ? CategoryModel(id: existingCategory.id, name: name, imageUrl: imageUrl, parentId: parentId)
        : CategoryModel(id: '', name: name, imageUrl: imageUrl, parentId: parentId);

    final result = existingCategory != null
        ? await _homeRepository.updateCategory(categoryToSave)
        : await _homeRepository.createCategory(categoryToSave);

    result.fold(
          (failure) => emit(state.copyWith(status: AdminCategoriesStatus.error, errorMessage: failure.message)),
          (_) => fetchAllCategories(), // Tải lại danh sách sau khi lưu thành công
    );
  }

  Future<void> deleteCategory(String categoryId) async {
    // TODO: Cần kiểm tra xem danh mục có sản phẩm hoặc danh mục con không trước khi xóa
    final result = await _homeRepository.deleteCategory(categoryId);
    result.fold(
          (failure) => emit(state.copyWith(status: AdminCategoriesStatus.error, errorMessage: failure.message)),
          (_) => fetchAllCategories(), // Tải lại danh sách
    );
  }
}