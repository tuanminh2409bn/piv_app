import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/admin/presentation/bloc/product_form_cubit.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/home/data/models/category_model.dart';

// ... phần còn lại của file giữ nguyên như phiên bản trước ...
class AdminProductFormPage extends StatelessWidget {
  final ProductModel? product;
  const AdminProductFormPage({super.key, this.product});

  static PageRoute<bool?> route({ProductModel? product}) {
    return MaterialPageRoute<bool?>(
      builder: (_) => AdminProductFormPage(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
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
  late final TextEditingController _nameController = TextEditingController();
  late final TextEditingController _descriptionController = TextEditingController();
  late bool _isFeatured = false;

  late final TextEditingController _packagingNameController = TextEditingController();
  late final TextEditingController _itemsPerCaseController = TextEditingController();
  late final TextEditingController _itemUnitController = TextEditingController();
  late final TextEditingController _agent1PriceController = TextEditingController();
  late final TextEditingController _agent2PriceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _packagingNameController.dispose();
    _itemsPerCaseController.dispose();
    _itemUnitController.dispose();
    _agent1PriceController.dispose();
    _agent2PriceController.dispose();
    super.dispose();
  }

  void _onSavePressed() {
    context.read<ProductFormCubit>().saveProduct(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      currentImageUrl: context.read<ProductFormCubit>().state.initialProduct?.imageUrl ?? '',
      packagingName: _packagingNameController.text.trim(),
      itemsPerCase: _itemsPerCaseController.text.trim(),
      itemUnit: _itemUnitController.text.trim(),
      prices: {
        'agent_1': _agent1PriceController.text.trim(),
        'agent_2': _agent2PriceController.text.trim(),
      },
      isFeatured: _isFeatured,
    );
  }

  void _updateControllers(ProductModel? product) {
    if (product == null) return;
    final firstOption = (product.packingOptions.isNotEmpty)
        ? product.packingOptions.first
        : null;

    _nameController.text = product.name;
    _descriptionController.text = product.description;
    if(mounted) {
      setState(() {
        _isFeatured = product.isFeatured;
      });
    }

    _packagingNameController.text = firstOption?.name ?? '';
    _itemsPerCaseController.text = firstOption?.quantityPerPackage.toString() ?? '';
    _itemUnitController.text = firstOption?.unit ?? '';
    _agent1PriceController.text = firstOption?.prices['agent_1']?.toStringAsFixed(0) ?? '';
    _agent2PriceController.text = firstOption?.prices['agent_2']?.toStringAsFixed(0) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductFormCubit, ProductFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == ProductFormStatus.success) {
          if(state.initialProduct != null) {
            _updateControllers(state.initialProduct);
          }
        } else if (state.status == ProductFormStatus.submissionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lưu sản phẩm thành công!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true);
        } else if (state.status == ProductFormStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Có lỗi xảy ra'), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state.status == ProductFormStatus.submitting;
        return Scaffold(
          appBar: AppBar(
            title: Text(state.isEditing ? 'Sửa Sản phẩm' : 'Thêm Sản phẩm mới'),
            actions: [
              if (!isSubmitting)
                IconButton(icon: const Icon(Icons.save_outlined), onPressed: _onSavePressed, tooltip: 'Lưu')
              else
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

  Widget _buildBody(BuildContext context, ProductFormState state) {
    if (state.status == ProductFormStatus.loading || state.status == ProductFormStatus.initial) {
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
              const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text('Đang tải danh mục...'))
            else
              ..._buildCategoryDropdowns(context, state),
            const SizedBox(height: 24),

            Text('Quy cách & Giá bán (Quy cách đầu tiên)', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            _buildTextField(controller: _packagingNameController, label: 'Tên quy cách (VD: Thùng 400 gói)'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField(controller: _itemsPerCaseController, label: 'Số lượng/Quy cách', keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(controller: _itemUnitController, label: 'Đơn vị lẻ (VD: gói, chai)')),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(controller: _agent1PriceController, label: 'Giá Đại lý cấp 1 / 1 đơn vị lẻ', keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField(controller: _agent2PriceController, label: 'Giá Đại lý cấp 2 / 1 đơn vị lẻ', keyboardType: TextInputType.number),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Sản phẩm nổi bật'),
              subtitle: const Text('Hiển thị trên trang chủ'),
              value: _isFeatured,
              onChanged: (bool value) => setState(() => _isFeatured = value),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context, ProductFormState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ảnh đại diện', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => context.read<ProductFormCubit>().pickImage(),
            borderRadius: BorderRadius.circular(12),
            child: (state.selectedImageFile != null)
                ? ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.file(state.selectedImageFile!, fit: BoxFit.cover))
                : (state.initialProduct?.imageUrl != null && state.initialProduct!.imageUrl.isNotEmpty)
                ? ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.network(state.initialProduct!.imageUrl, fit: BoxFit.cover))
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

  List<Widget> _buildCategoryDropdowns(BuildContext context, ProductFormState state) {
    List<Widget> dropdowns = [];
    for (int i = 0; i < state.categoryLevels.length; i++) {
      dropdowns.add(
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: DropdownButtonFormField<CategoryModel>(
            value: (i < state.selectedCategoryPath.length) ? state.selectedCategoryPath[i] : null,
            isExpanded: true,
            decoration: InputDecoration(labelText: 'Chọn danh mục cấp ${i + 1}', border: const OutlineInputBorder()),
            hint: const Text('-- Chọn --'),
            items: state.categoryLevels[i].map((CategoryModel category) {
              return DropdownMenuItem<CategoryModel>(value: category, child: Text(category.name));
            }).toList(),
            onChanged: (CategoryModel? newValue) => context.read<ProductFormCubit>().selectCategory(newValue, i),
            validator: (value) {
              if (i == 0 && value == null) return 'Vui lòng chọn ít nhất một danh mục';
              return null;
            },
          ),
        ),
      );
    }
    return dropdowns;
  }

  Widget _buildTextField({required TextEditingController controller, required String label, int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), alignLabelWithHint: true),
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.number ? [FilteringTextInputFormatter.digitsOnly] : [],
      validator: (value) {
        if (label.contains('Tên') && (value == null || value.trim().isEmpty)) {
          return '$label không được để trống';
        }
        return null;
      },
    );
  }
}