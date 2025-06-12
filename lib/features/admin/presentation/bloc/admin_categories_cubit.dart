import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/home/data/models/category_model.dart';
import 'package:piv_app/features/home/domain/repositories/home_repository.dart';
import 'dart:developer' as developer;

part 'admin_categories_state.dart';

class AdminCategoriesCubit extends Cubit<AdminCategoriesState> {
  final HomeRepository _homeRepository;

  AdminCategoriesCubit({required HomeRepository homeRepository})
      : _homeRepository = homeRepository,
        super(const AdminCategoriesState());

  /// Tải tất cả các danh mục từ repository
  Future<void> fetchAllCategories() async {
    emit(state.copyWith(status: AdminCategoriesStatus.loading));
    developer.log('AdminCategoriesCubit: Fetching all categories...', name: 'AdminCategoriesCubit');

    final result = await _homeRepository.getAllCategories();

    result.fold(
          (failure) {
        emit(state.copyWith(status: AdminCategoriesStatus.error, errorMessage: failure.message));
      },
          (categories) {
        emit(state.copyWith(
          status: AdminCategoriesStatus.success,
          allCategories: categories,
        ));
      },
    );
  }

// TODO: Implement các phương thức create, update, delete
// Future<void> createCategory(CategoryModel category) async { ... }
// Future<void> updateCategory(CategoryModel category) async { ... }
// Future<void> deleteCategory(String categoryId) async { ... }
}
