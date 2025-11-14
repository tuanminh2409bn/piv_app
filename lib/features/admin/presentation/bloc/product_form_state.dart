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
  final File? selectedImageFile;
  final String? errorMessage;
  final String version;
  final List<UserModel> agents;
  final UserModel? selectedOwnerAgent;

  const ProductFormState({
    this.status = ProductFormStatus.initial,
    this.isEditing = false,
    this.initialProduct,
    this.allCategories = const [],
    this.categoryLevels = const [],
    this.selectedCategoryPath = const [],
    this.selectedImageFile,
    this.errorMessage,
    required this.version,
    this.agents = const [],
    this.selectedOwnerAgent,
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
    selectedImageFile,
    errorMessage,
    version,
    agents,
    selectedOwnerAgent,
  ];

  ProductFormState copyWith({
    ProductFormStatus? status,
    bool? isEditing,
    ProductModel? initialProduct,
    List<CategoryModel>? allCategories,
    List<List<CategoryModel>>? categoryLevels,
    List<CategoryModel?>? selectedCategoryPath,
    File? selectedImageFile,
    String? errorMessage,
    List<UserModel>? agents,
    UserModel? selectedOwnerAgent,
    bool clearOwnerAgent = false,
  }) {
    return ProductFormState(
      status: status ?? this.status,
      isEditing: isEditing ?? this.isEditing,
      initialProduct: initialProduct ?? this.initialProduct,
      allCategories: allCategories ?? this.allCategories,
      categoryLevels: categoryLevels ?? this.categoryLevels,
      selectedCategoryPath: selectedCategoryPath ?? this.selectedCategoryPath,
      selectedImageFile: selectedImageFile ?? this.selectedImageFile,
      errorMessage: errorMessage ?? this.errorMessage,
      version: const Uuid().v4(),
      agents: agents ?? this.agents,
      selectedOwnerAgent: clearOwnerAgent ? null : (selectedOwnerAgent ?? this.selectedOwnerAgent),
    );
  }
}
