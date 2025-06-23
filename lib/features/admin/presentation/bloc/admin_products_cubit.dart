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
        ));
        // Áp dụng lại bộ lọc sau khi tải
        searchProducts(state.searchQuery);
      },
    );
  }

  void searchProducts(String query) {
    emit(state.copyWith(searchQuery: query));
    if (query.isEmpty) {
      emit(state.copyWith(filteredProducts: state.allProducts));
      return;
    }

    final lowerCaseQuery = query.toLowerCase();
    final filtered = state.allProducts.where((product) {
      return product.name.toLowerCase().contains(lowerCaseQuery);
    }).toList();

    emit(state.copyWith(filteredProducts: filtered));
  }

  Future<void> toggleIsFeatured(String productId, bool currentValue) async {
    final result = await _homeRepository.updateProductField(productId, {'isFeatured': !currentValue});
    if (result.isRight()) {
      // Cập nhật trạng thái trong bộ nhớ mà không cần gọi lại server
      final updatedAllProducts = state.allProducts.map((p) {
        if (p.id == productId) {
          return ProductModel(
              id: p.id,
              name: p.name,
              description: p.description,
              imageUrl: p.imageUrl,
              categoryId: p.categoryId,
              isFeatured: !currentValue,
              createdAt: p.createdAt,
              attributes: p.attributes,
              packingOptions: p.packingOptions);
        }
        return p;
      }).toList();
      emit(state.copyWith(allProducts: updatedAllProducts));
      searchProducts(state.searchQuery); // Áp dụng lại tìm kiếm
    } else {
      emit(state.copyWith(status: AdminProductsStatus.error, errorMessage: "Cập nhật thất bại"));
    }
  }

  Future<void> deleteProduct(String productId) async {
    final result = await _homeRepository.deleteProduct(productId);
    result.fold(
          (failure) {
        emit(state.copyWith(status: AdminProductsStatus.error, errorMessage: failure.message));
      },
          (_) {
        fetchAllProducts();
      },
    );
  }
}