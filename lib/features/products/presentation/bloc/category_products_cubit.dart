// lib/features/products/presentation/bloc/category_products_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/home/data/models/category_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/home/domain/repositories/home_repository.dart';

part 'category_products_state.dart';

class CategoryProductsCubit extends Cubit<CategoryProductsState> {
  final HomeRepository _homeRepository;

  CategoryProductsCubit({required HomeRepository homeRepository})
      : _homeRepository = homeRepository,
        super(const CategoryProductsState());

  /// Tải dữ liệu cho một danh mục cụ thể (bao gồm danh mục con và sản phẩm của nó)

  // BƯỚC 1: SỬA ĐỊNH NGHĨA HÀM (Thêm tham số {String? currentUserId})
  Future<void> fetchDataForCategory(CategoryModel category, {String? currentUserId}) async {
    // Phát ra trạng thái loading và cập nhật danh mục hiện tại đang xem
    emit(state.copyWith(status: CategoryProductsStatus.loading, currentCategory: category));

    // Tải danh mục con trước
    final subCategoriesResult = await _homeRepository.getSubCategories(category.id);

    // Sử dụng fold để xử lý kết quả một cách an toàn
    await subCategoriesResult.fold(
      // Nếu tải danh mục con thất bại -> báo lỗi
          (failure) async {
        emit(state.copyWith(status: CategoryProductsStatus.error, errorMessage: failure.message));
      },
      // Nếu tải danh mục con thành công -> tiếp tục tải sản phẩm
          (subCategories) async {

        // BƯỚC 2: SỬ DỤNG THAM SỐ (Truyền currentUserId xuống repository)
        final productsResult = await _homeRepository.getProductsByCategoryId(
            category.id,
            currentUserId: currentUserId // <-- Đây là dòng 34 (hoặc tương tự) gây lỗi
        );

        productsResult.fold(
          // Nếu tải sản phẩm thất bại -> báo lỗi, nhưng vẫn giữ lại danh mục con đã tải
              (failure) {
            emit(state.copyWith(
              status: CategoryProductsStatus.error,
              errorMessage: failure.message,
              subCategories: subCategories,
            ));
          },
          // Nếu cả hai đều thành công -> cập nhật state với đầy đủ dữ liệu
              (products) {
            emit(state.copyWith(
              status: CategoryProductsStatus.success,
              subCategories: subCategories,
              products: products,
            ));
          },
        );
      },
    );
  }
}