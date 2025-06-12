import 'dart:io'; // Import để sử dụng kiểu File
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/home/data/models/category_model.dart';
import 'package:piv_app/features/home/domain/repositories/home_repository.dart';
import 'package:piv_app/features/admin/data/repositories/storage_repository.dart'; // Import StorageRepository
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;

part 'product_form_state.dart';

class ProductFormCubit extends Cubit<ProductFormState> {
  final HomeRepository _homeRepository;
  final StorageRepository _storageRepository;

  ProductFormCubit({
    required HomeRepository homeRepository,
    required StorageRepository storageRepository,
  })  : _homeRepository = homeRepository,
        _storageRepository = storageRepository,
        super(ProductFormState.initial());

  /// Tải dữ liệu ban đầu cần thiết cho form (danh sách danh mục)
  /// và khởi tạo form cho việc sửa (nếu có)
  Future<void> initializeForm({ProductModel? productToEdit}) async {
    emit(state.copyWith(status: ProductFormStatus.loading));

    final categoriesResult = await _homeRepository.getAllCategories();

    categoriesResult.fold(
          (failure) {
        emit(state.copyWith(status: ProductFormStatus.error, errorMessage: failure.message));
      },
          (allCategories) {
        final topLevelCategories = allCategories.where((c) => c.parentId == null).toList();

        List<List<CategoryModel>> initialLevels = [topLevelCategories];
        List<CategoryModel?> initialPath = [null];

        // Nếu là chế độ sửa, xây dựng lại đường dẫn và các cấp dropdown
        if (productToEdit != null && productToEdit.categoryId.isNotEmpty) {
          final pathAndLevels = _buildInitialPath(productToEdit.categoryId, allCategories, topLevelCategories);
          initialPath = pathAndLevels.$1;
          initialLevels = pathAndLevels.$2;
        }

        emit(state.copyWith(
          status: ProductFormStatus.success,
          allCategories: allCategories,
          categoryLevels: initialLevels,
          selectedCategoryPath: initialPath,
          initialProduct: productToEdit,
          isEditing: productToEdit != null,
        ));
      },
    );
  }

  /// Hàm được gọi khi người dùng chọn một danh mục ở một cấp độ nào đó
  void selectCategory(CategoryModel? selectedCategory, int level) {
    if (state.status != ProductFormStatus.success && state.status != ProductFormStatus.error) return;

    // Cắt đường dẫn và các cấp danh mục từ cấp hiện tại trở đi
    List<CategoryModel?> newPath = List.from(state.selectedCategoryPath.take(level + 1));
    newPath[level] = selectedCategory;

    List<List<CategoryModel>> newLevels = List.from(state.categoryLevels.take(level + 1));

    // Nếu người dùng chọn một danh mục (không phải "none")
    if (selectedCategory != null) {
      // Tìm các danh mục con của danh mục vừa chọn
      final subCategories = state.allCategories
          .where((cat) => cat.parentId == selectedCategory.id)
          .toList();

      // Nếu có danh mục con, thêm một cấp dropdown mới
      if (subCategories.isNotEmpty) {
        newLevels.add(subCategories);
        newPath.add(null);
      }
    }

    emit(state.copyWith(
      selectedCategoryPath: newPath,
      categoryLevels: newLevels,
      status: ProductFormStatus.success,
    ));
  }

  /// Hàm helper để xây dựng đường dẫn ban đầu khi sửa sản phẩm
  (List<CategoryModel?>, List<List<CategoryModel>>) _buildInitialPath(
      String leafCategoryId,
      List<CategoryModel> allCategories,
      List<CategoryModel> topLevelCategories
      ) {
    List<CategoryModel> reversedPath = [];
    CategoryModel? current;

    try {
      current = allCategories.firstWhere((c) => c.id == leafCategoryId);
    } catch (e) {
      return ([null], [topLevelCategories]);
    }

    while (current != null) {
      reversedPath.add(current);
      final parentId = current.parentId;
      if (parentId == null) break;

      try {
        current = allCategories.firstWhere((c) => c.id == parentId);
      } catch(e) {
        break;
      }
    }

    final finalPath = reversedPath.reversed.toList();
    List<List<CategoryModel>> finalLevels = [topLevelCategories];

    for (int i = 0; i < finalPath.length - 1; i++) {
      final parentIdOfNextLevel = finalPath[i].id;
      final subCats = allCategories.where((c) => c.parentId == parentIdOfNextLevel).toList();
      if (subCats.isNotEmpty) {
        finalLevels.add(subCats);
      } else {
        break;
      }
    }

    if (finalPath.length > finalLevels.length) {
      finalPath.removeLast();
    }

    return (finalPath.cast<CategoryModel?>(), finalLevels);
  }

  /// Chọn ảnh từ thư viện của thiết bị
  Future<void> pickImage() async {
    final result = await _storageRepository.pickImageFromGallery();
    result.fold(
            (failure) {
          developer.log('Image picking failed: ${failure.message}', name: 'ProductFormCubit');
        },
            (imageFile) {
          // Cập nhật state với file ảnh đã chọn
          emit(state.copyWith(selectedImageFile: imageFile, status: ProductFormStatus.success));
        }
    );
  }

  /// Lưu sản phẩm (thêm mới hoặc cập nhật)
  Future<void> saveProduct({
    required String name,
    required String description,
    required String currentImageUrl, // URL ảnh hiện tại (nếu có)
    required String basePrice,
    required String unit,
    required bool isFeatured,
  }) async {
    emit(state.copyWith(status: ProductFormStatus.submitting));

    final selectedCategoryId = state.finalSelectedCategory?.id;
    if (selectedCategoryId == null) {
      emit(state.copyWith(status: ProductFormStatus.error, errorMessage: 'Vui lòng chọn danh mục cấp cuối cùng.'));
      return;
    }

    final priceValue = double.tryParse(basePrice);
    if (priceValue == null) {
      emit(state.copyWith(status: ProductFormStatus.error, errorMessage: 'Giá sản phẩm không hợp lệ.'));
      return;
    }

    String finalImageUrl = currentImageUrl;

    // Nếu có file ảnh mới được chọn, tải nó lên trước
    if (state.selectedImageFile != null) {
      final uploadResult = await _storageRepository.uploadImage(state.selectedImageFile!);
      await uploadResult.fold(
            (failure) {
          emit(state.copyWith(status: ProductFormStatus.error, errorMessage: 'Lỗi tải ảnh lên: ${failure.message}'));
          return;
        },
            (downloadUrl) {
          finalImageUrl = downloadUrl; // Lấy URL mới sau khi tải lên thành công
        },
      );
      // Nếu đã có lỗi xảy ra ở bước tải ảnh, dừng lại
      if (state.status == ProductFormStatus.error) return;
    }

    final productToSave = ProductModel(
      id: state.initialProduct?.id ?? '',
      name: name,
      description: description,
      imageUrl: finalImageUrl, // Sử dụng URL cuối cùng
      categoryId: selectedCategoryId,
      basePrice: priceValue,
      unit: unit,
      isFeatured: isFeatured,
      createdAt: state.initialProduct?.createdAt,
    );

    final result = state.isEditing
        ? await _homeRepository.updateProduct(productToSave)
        : await _homeRepository.createProduct(productToSave);

    result.fold(
          (failure) {
        emit(state.copyWith(status: ProductFormStatus.error, errorMessage: failure.message));
      },
          (_) {
        emit(state.copyWith(status: ProductFormStatus.submissionSuccess));
      },
    );
  }
}
