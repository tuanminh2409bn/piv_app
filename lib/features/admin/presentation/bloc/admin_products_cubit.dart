import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/home/domain/repositories/home_repository.dart';
import 'dart:developer' as developer;

part 'admin_products_state.dart';

class AdminProductsCubit extends Cubit<AdminProductsState> {
  final HomeRepository _homeRepository;

  AdminProductsCubit({required HomeRepository homeRepository})
      : _homeRepository = homeRepository,
        super(const AdminProductsState());

  /// Tải tất cả các sản phẩm trong hệ thống
  Future<void> fetchAllProducts() async {
    emit(state.copyWith(status: AdminProductsStatus.loading));
    developer.log('AdminProductsCubit: Fetching all products...', name: 'AdminProductsCubit');

    final result = await _homeRepository.getAllProducts();

    result.fold(
          (failure) {
        emit(state.copyWith(status: AdminProductsStatus.error, errorMessage: failure.message));
      },
          (products) {
        emit(state.copyWith(
          status: AdminProductsStatus.success,
          allProducts: products,
          filteredProducts: products, // Ban đầu, danh sách lọc giống danh sách đầy đủ
        ));
      },
    );
  }

  /// Lọc danh sách sản phẩm dựa trên từ khóa tìm kiếm
  void searchProducts(String query) {
    if (query.isEmpty) {
      // Nếu không tìm kiếm, hiển thị lại tất cả sản phẩm
      emit(state.copyWith(filteredProducts: state.allProducts));
      return;
    }

    final lowerCaseQuery = query.toLowerCase();
    final filtered = state.allProducts.where((product) {
      // Tìm kiếm theo tên sản phẩm (không phân biệt hoa thường)
      return product.name.toLowerCase().contains(lowerCaseQuery);
    }).toList();

    emit(state.copyWith(filteredProducts: filtered));
  }

  /// Xóa một sản phẩm và tải lại danh sách
  Future<void> deleteProduct(String productId) async {
    // Không cần emit loading để tránh giật màn hình
    final result = await _homeRepository.deleteProduct(productId);
    result.fold(
          (failure) {
        // Có thể hiển thị lỗi qua một state riêng hoặc SnackBar
        emit(state.copyWith(status: AdminProductsStatus.error, errorMessage: failure.message));
      },
          (_) {
        // Sau khi xóa thành công, tải lại danh sách
        fetchAllProducts();
      },
    );
  }
}
