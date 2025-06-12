import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/admin/presentation/bloc/product_form_cubit.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/home/data/models/category_model.dart';

class AdminProductFormPage extends StatelessWidget {
  // Sản phẩm cần sửa (có thể null nếu đang ở chế độ thêm mới)
  final ProductModel? product;
  const AdminProductFormPage({super.key, this.product});

  // Kiểu trả về là bool? để báo hiệu cho trang trước biết việc lưu có thành công không
  static PageRoute<bool?> route({ProductModel? product}) {
    return MaterialPageRoute<bool?>(
      builder: (_) => AdminProductFormPage(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cung cấp một instance mới của ProductFormCubit và khởi tạo form
    return BlocProvider(
      create: (_) => sl<ProductFormCubit>()..initializeForm(productToEdit: product),
      child: const ProductFormView(),
    );
  }
}

class ProductFormView extends StatefulWidget {
  const ProductFormView({super.key});
  @override
  State<ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends State<ProductFormView> {
  final _formKey = GlobalKey<FormState>();
  // Sử dụng TextEditingController để quản lý dữ liệu trong các trường text
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _basePriceController;
  late final TextEditingController _unitController;
  // Giá trị của Switch sẽ được quản lý cục bộ và gửi đi khi lưu
  late bool _isFeatured;

  @override
  void initState() {
    super.initState();
    // Lấy cubit từ context để truy cập state ban đầu
    final initialProduct = context.read<ProductFormCubit>().state.initialProduct;

    // Khởi tạo các controller với dữ liệu của sản phẩm (nếu đang ở chế độ sửa)
    _nameController = TextEditingController(text: initialProduct?.name);
    _descriptionController = TextEditingController(text: initialProduct?.description);
    _basePriceController = TextEditingController(text: initialProduct?.basePrice.toStringAsFixed(0) ?? '');
    _unitController = TextEditingController(text: initialProduct?.unit);
    _isFeatured = initialProduct?.isFeatured ?? false;
  }

  @override
  void dispose() {
    // Luôn dispose các controller để tránh rò rỉ bộ nhớ
    _nameController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  // Hàm được gọi khi nhấn nút Lưu
  void _onSavePressed() {
    // Kiểm tra xem form có hợp lệ không
    if (_formKey.currentState!.validate()) {
      // Lấy URL ảnh hiện tại từ sản phẩm ban đầu để truyền vào cubit
      final currentImageUrl = context.read<ProductFormCubit>().state.initialProduct?.imageUrl ?? '';
      context.read<ProductFormCubit>().saveProduct(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        currentImageUrl: currentImageUrl, // Truyền URL hiện tại (nếu có)
        basePrice: _basePriceController.text.trim(),
        unit: _unitController.text.trim(),
        isFeatured: _isFeatured,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductFormCubit, ProductFormState>(
      listener: (context, state) {
        if (state.status == ProductFormStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Có lỗi xảy ra'), backgroundColor: Colors.red),
          );
        } else if (state.status == ProductFormStatus.submissionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lưu sản phẩm thành công!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true); // Trả về 'true' để báo hiệu thành công
        }
      },
      builder: (context, state) {
        final isSubmitting = state.status == ProductFormStatus.submitting;

        return Scaffold(
          appBar: AppBar(
            title: Text(state.isEditing ? 'Sửa Sản phẩm' : 'Thêm Sản phẩm mới'),
            actions: [
              if (!isSubmitting)
                IconButton(
                  icon: const Icon(Icons.save_outlined),
                  onPressed: _onSavePressed,
                  tooltip: 'Lưu',
                )
              else
              // Hiển thị vòng tròn tải khi đang lưu
                const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))),
                )
            ],
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  // Widget cho phần thân của trang
  Widget _buildBody(BuildContext context, ProductFormState state) {
    // Hiển thị vòng tròn tải khi đang load dữ liệu ban đầu (danh mục)
    if (state.status == ProductFormStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePicker(context, state),
            const SizedBox(height: 24),
            _buildTextField(controller: _nameController, label: 'Tên sản phẩm'),
            const SizedBox(height: 16),
            _buildTextField(controller: _descriptionController, label: 'Mô tả', maxLines: 5),
            const SizedBox(height: 24),

            Text('Chọn danh mục', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            if (state.categoryLevels.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Đang tải danh mục...'),
              )
            else
            // Xây dựng các dropdown động từ state
              ..._buildCategoryDropdowns(context, state),
            const SizedBox(height: 16),

            _buildTextField(controller: _basePriceController, label: 'Giá', keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField(controller: _unitController, label: 'Đơn vị tính (VD: Bao 25kg)'),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Sản phẩm nổi bật'),
              subtitle: const Text('Hiển thị trên trang chủ'),
              value: _isFeatured,
              onChanged: (bool value) {
                setState(() {
                  _isFeatured = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  // Widget để chọn ảnh và xem trước
  Widget _buildImagePicker(BuildContext context, ProductFormState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ảnh đại diện', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              context.read<ProductFormCubit>().pickImage();
            },
            borderRadius: BorderRadius.circular(12),
            child: (state.selectedImageFile != null)
            // Hiển thị ảnh mới chọn từ thiết bị
                ? ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.file(state.selectedImageFile!, fit: BoxFit.cover),
            )
            // Hiển thị ảnh cũ từ server (nếu đang sửa)
                : (state.initialProduct?.imageUrl != null && state.initialProduct!.imageUrl.isNotEmpty)
                ? ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.network(state.initialProduct!.imageUrl, fit: BoxFit.cover),
            )
            // Hiển thị placeholder nếu không có ảnh nào
                : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey.shade600),
                  const SizedBox(height: 8),
                  const Text('Nhấn để chọn ảnh'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Hàm để tạo các dropdown động
  List<Widget> _buildCategoryDropdowns(BuildContext context, ProductFormState state) {
    List<Widget> dropdowns = [];
    for (int i = 0; i < state.categoryLevels.length; i++) {
      dropdowns.add(
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: DropdownButtonFormField<CategoryModel>(
            // Thêm kiểm tra này để tránh RangeError
            value: (i < state.selectedCategoryPath.length) ? state.selectedCategoryPath[i] : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Chọn danh mục cấp ${i + 1}',
              border: const OutlineInputBorder(),
            ),
            hint: const Text('-- Chọn --'),
            items: state.categoryLevels[i].map((CategoryModel category) {
              return DropdownMenuItem<CategoryModel>(
                value: category,
                child: Text(category.name),
              );
            }).toList(),
            onChanged: (CategoryModel? newValue) {
              context.read<ProductFormCubit>().selectCategory(newValue, i);
            },
            validator: (value) {
              // Validate nếu đây là dropdown cấp cuối cùng và chưa có lựa chọn
              if (i == state.categoryLevels.length - 1 && value == null) {
                final parentHasChildren = state.allCategories.any((cat) => cat.parentId == state.selectedCategoryPath[i-1]?.id);
                if (parentHasChildren) {
                  return 'Vui lòng chọn danh mục cấp cuối cùng';
                }
              }
              return null;
            },
          ),
        ),
      );
    }
    return dropdowns;
  }

  // Hàm helper để tạo TextFormField
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          alignLabelWithHint: true),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (value) {
        if (label != 'Mô tả' && (value == null || value.trim().isEmpty)) {
          return '$label không được để trống';
        }
        return null;
      },
    );
  }
}
