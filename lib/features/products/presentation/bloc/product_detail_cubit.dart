import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/home/domain/repositories/home_repository.dart';
import 'dart:developer' as developer;

part 'product_detail_state.dart';

class ProductDetailCubit extends Cubit<ProductDetailState> {
  final HomeRepository _homeRepository;

  ProductDetailCubit({required HomeRepository homeRepository})
      : _homeRepository = homeRepository,
        super(const ProductDetailState());

  Future<void> fetchProductDetail(String productId) async {
    if (productId.isEmpty) {
      emit(state.copyWith(status: ProductDetailStatus.error, errorMessage: "ID sản phẩm không hợp lệ."));
      return;
    }
    emit(const ProductDetailState(status: ProductDetailStatus.loading));
    developer.log('ProductDetailCubit: Fetching detail for product ID: $productId', name: 'ProductDetailCubit');

    final result = await _homeRepository.getProductById(productId);

    result.fold(
          (failure) {
        developer.log('ProductDetailCubit: Failed to fetch product detail - ${failure.message}', name: 'ProductDetailCubit');
        emit(state.copyWith(status: ProductDetailStatus.error, errorMessage: failure.message));
      },
          (product) {
        developer.log('ProductDetailCubit: Product detail fetched successfully - ${product.name}', name: 'ProductDetailCubit');
        emit(state.copyWith(status: ProductDetailStatus.success, product: product));
      },
    );
  }

  void incrementQuantity() {
    if (state.product == null) return;
    emit(state.copyWith(quantity: state.quantity + 1));
  }

  void decrementQuantity() {
    if (state.quantity > 1) {
      emit(state.copyWith(quantity: state.quantity - 1));
    }
  }

  // ** PHƯƠNG THỨC MỚI ĐỂ NHẬN SỐ LƯỢNG TỪ DIALOG **
  void setQuantity(int newQuantity) {
    if (newQuantity > 0) {
      emit(state.copyWith(quantity: newQuantity));
    }
  }
}
