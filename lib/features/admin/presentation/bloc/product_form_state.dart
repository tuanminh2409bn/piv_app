part of 'product_form_cubit.dart';

enum ProductFormStatus {
  initial,
  loading,
  success,
  submitting,
  submissionSuccess,
  error,
}

class ProductFormState extends Equatable {
  final ProductFormStatus status;
  final bool isEditing;
  final ProductModel? initialProduct;
  final List<CategoryModel> allCategories;
  final List<List<CategoryModel>> categoryLevels;
  final List<CategoryModel?> selectedCategoryPath;

  // ** THÊM TRƯỜNG NÀY ĐỂ LƯU FILE ẢNH ĐÃ CHỌN **
  final File? selectedImageFile;

  final String? errorMessage;
  final String version;

  const ProductFormState({
    this.status = ProductFormStatus.initial,
    this.isEditing = false,
    this.initialProduct,
    this.allCategories = const [],
    this.categoryLevels = const [],
    this.selectedCategoryPath = const [],
    this.selectedImageFile, // << THÊM VÀO CONSTRUCTOR
    this.errorMessage,
    required this.version,
  });

  factory ProductFormState.initial() {
    return ProductFormState(version: const Uuid().v4());
  }

  CategoryModel? get finalSelectedCategory {
    if (selectedCategoryPath.isEmpty) return null;
    return selectedCategoryPath.lastWhere((cat) => cat != null, orElse: () => null);
  }

  @override
  List<Object?> get props => [
    status,
    isEditing,
    initialProduct,
    allCategories,
    categoryLevels,
    selectedCategoryPath,
    selectedImageFile, // << THÊM VÀO PROPS
    errorMessage,
    version,
  ];

  ProductFormState copyWith({
    ProductFormStatus? status,
    bool? isEditing,
    ProductModel? initialProduct,
    List<CategoryModel>? allCategories,
    List<List<CategoryModel>>? categoryLevels,
    List<CategoryModel?>? selectedCategoryPath,
    File? selectedImageFile, // << THÊM VÀO COPYWITH
    String? errorMessage,
  }) {
    return ProductFormState(
      status: status ?? this.status,
      isEditing: isEditing ?? this.isEditing,
      initialProduct: initialProduct ?? this.initialProduct,
      allCategories: allCategories ?? this.allCategories,
      categoryLevels: categoryLevels ?? this.categoryLevels,
      selectedCategoryPath: selectedCategoryPath ?? this.selectedCategoryPath,
      selectedImageFile: selectedImageFile ?? this.selectedImageFile, // << GÁN GIÁ TRỊ
      errorMessage: errorMessage ?? this.errorMessage,
      version: const Uuid().v4(),
    );
  }
}
