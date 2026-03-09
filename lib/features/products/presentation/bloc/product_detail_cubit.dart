import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/home/domain/repositories/home_repository.dart';
import 'package:piv_app/data/models/packaging_option_model.dart';
import 'dart:developer' as developer;
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/data/models/user_model.dart';

part 'product_detail_state.dart';

class ProductDetailCubit extends Cubit<ProductDetailState> {
  final HomeRepository _homeRepository;
  final AuthBloc _authBloc; // <-- THÊM MỚI

  ProductDetailCubit({
    required HomeRepository homeRepository,
    required AuthBloc authBloc, // <-- THÊM MỚI
  })  : _homeRepository = homeRepository,
        _authBloc = authBloc, // <-- THÊM MỚI
        super(const ProductDetailState());

  Future<void> fetchProductDetail(String productId) async {
    if (productId.isEmpty) {
      emit(state.copyWith(status: ProductDetailStatus.error, errorMessage: "ID sản phẩm không hợp lệ."));
      return;
    }
    emit(const ProductDetailState(status: ProductDetailStatus.loading));
    developer.log('ProductDetailCubit: Fetching detail for product ID: $productId', name: 'ProductDetailCubit');

    // --- SỬA ĐỔI: Lấy currentUserId từ AuthBloc ---
    String? currentUserId;
    final authState = _authBloc.state;
    if (authState is AuthAuthenticated) {
      currentUserId = authState.user.id;
    }
    // --- KẾT THÚC SỬA ĐỔI ---

    // --- SỬA ĐỔI: Truyền currentUserId vào repository ---
    final result = await _homeRepository.getProductById(
      productId,
      currentUserId: currentUserId, // <-- Truyền vào đây
    );
    // --- KẾT THÚC SỬA ĐỔI ---

    result.fold(
          (failure) {
        developer.log('ProductDetailCubit: Failed to fetch product detail - ${failure.message}', name: 'ProductDetailCubit');
        emit(state.copyWith(status: ProductDetailStatus.error, errorMessage: failure.message));
      },
          (product) {
        developer.log('ProductDetailCubit: Fetched Product Data: ${product.name}', name: 'ProductDetailCubit');

        // --- TỰ ĐỘNG THÊM QUY CÁCH LẺ NẾU CHƯA CÓ ---
        List<PackagingOptionModel> finalOptions = List.from(product.packingOptions);
        bool hasRetail = finalOptions.any((opt) => opt.quantityPerPackage == 1);
        
        if (!hasRetail && finalOptions.isNotEmpty) {
          final caseOption = finalOptions.first;
          final retailOption = PackagingOptionModel(
            name: 'Lẻ ${caseOption.unit}',
            quantityPerPackage: 1,
            unit: caseOption.unit,
            prices: caseOption.prices,
          );
          finalOptions.insert(0, retailOption); // Thêm vào đầu danh sách
        }

        // Tạo bản sao ProductModel với danh sách options đã cập nhật
        final updatedProduct = ProductModel(
          id: product.id,
          name: product.name,
          description: product.description,
          imageUrl: product.imageUrl,
          categoryId: product.categoryId,
          isFeatured: product.isFeatured,
          createdAt: product.createdAt,
          attributes: product.attributes,
          packingOptions: finalOptions,
          productType: product.productType,
          isPrivate: product.isPrivate,
          ownerAgentId: product.ownerAgentId,
        );

        PackagingOptionModel? defaultOption;
        if (finalOptions.isNotEmpty) {
          // Ưu tiên chọn THÙNG làm mặc định (quy cách có quantityPerPackage lớn nhất hoặc > 1)
          try {
            defaultOption = finalOptions.firstWhere(
              (opt) => opt.quantityPerPackage > 1
            );
          } catch (_) {
            defaultOption = finalOptions.first;
          }
        }

        emit(state.copyWith(
          status: ProductDetailStatus.success,
          product: updatedProduct,
          selectedPackagingOption: defaultOption,
        ));
      },
    );
  }

  void selectPackagingOption(PackagingOptionModel option) {
    emit(state.copyWith(
      selectedPackagingOption: option,
      quantity: 1,
    ));
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

  void setQuantity(int newQuantity) {
    if (newQuantity > 0) {
      emit(state.copyWith(quantity: newQuantity));
    }
  }
}