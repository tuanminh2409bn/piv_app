// lib/features/admin/presentation/pages/admin_categories_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_categories_cubit.dart';
import 'package:piv_app/features/home/data/models/category_model.dart';

class AdminCategoriesPage extends StatelessWidget {
  const AdminCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdminCategoriesCubit>()..fetchAllCategories(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý Danh mục'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _AdminCategoriesViewState.showCategoryFormDialog(context),
          child: const Icon(Icons.add),
        ),
        body: const AdminCategoriesView(),
      ),
    );
  }
}

class AdminCategoriesView extends StatelessWidget {
  const AdminCategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminCategoriesCubit, AdminCategoriesState>(
      listener: (context, state) {
        if (state.status == AdminCategoriesStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red));
        }
      },
      builder: (context, state) {
        if (state.status == AdminCategoriesStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final topLevelCategories = state.topLevelCategories;
        if (topLevelCategories.isEmpty) {
          return const Center(child: Text('Chưa có danh mục nào.'));
        }

        return RefreshIndicator(
          onRefresh: () async => context.read<AdminCategoriesCubit>().fetchAllCategories(),
          child: ListView(
            padding: const EdgeInsets.all(8.0),
            children: topLevelCategories.map((category) {
              return _AdminCategoriesViewState.buildCategoryTree(context, category, state.allCategories, 0);
            }).toList(),
          ),
        );
      },
    );
  }
}

// Chuyển các hàm helper thành static để có thể gọi từ bên ngoài
class _AdminCategoriesViewState {
  static Widget buildCategoryTree(BuildContext context, CategoryModel category, List<CategoryModel> allCategories, int level) {
    final subCategories = allCategories.where((c) => c.parentId == category.id).toList();
    const double indentationStep = 20.0;

    return ExpansionTile(
      tilePadding: EdgeInsets.only(left: indentationStep * level, right: 8.0),
      leading: Icon(subCategories.isNotEmpty ? Icons.folder_open_rounded : Icons.article_outlined, color: subCategories.isNotEmpty ? Colors.amber.shade800 : Colors.grey.shade600),
      title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.green), onPressed: () => showCategoryFormDialog(context, parentCategory: category), tooltip: 'Thêm danh mục con'),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey), onPressed: () => showCategoryFormDialog(context, categoryToEdit: category), tooltip: 'Sửa danh mục này'),
          IconButton(icon: Icon(Icons.delete_outline, size: 20, color: Theme.of(context).colorScheme.error), onPressed: () => _showDeleteConfirmDialog(context, category, subCategories.isNotEmpty), tooltip: 'Xóa danh mục'),
        ],
      ),
      children: subCategories.map((sub) => buildCategoryTree(context, sub, allCategories, level + 1)).toList(),
    );
  }

  static void _showDeleteConfirmDialog(BuildContext context, CategoryModel category, bool hasChildren) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(hasChildren
            ? 'Danh mục "${category.name}" có chứa các danh mục con. Bạn không thể xóa. Vui lòng xóa hết các danh mục con trước.'
            : 'Bạn có chắc chắn muốn xóa danh mục "${category.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('HỦY')),
          if (!hasChildren)
            TextButton(
              onPressed: () {
                context.read<AdminCategoriesCubit>().deleteCategory(category.id);
                Navigator.of(dialogContext).pop();
              },
              child: Text('XÓA', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
    );
  }

  static void showCategoryFormDialog(BuildContext context, {CategoryModel? categoryToEdit, CategoryModel? parentCategory}) {
    final cubit = context.read<AdminCategoriesCubit>();
    final allCategories = (cubit.state).allCategories;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: categoryToEdit?.name ?? '');
    final imageUrlController = TextEditingController(text: categoryToEdit?.imageUrl ?? '');
    String? selectedParentId = categoryToEdit?.parentId ?? parentCategory?.id;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(categoryToEdit != null ? 'Sửa Danh mục' : 'Thêm Danh mục mới'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên danh mục'), validator: (v) => v!.isEmpty ? 'Không được để trống' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: imageUrlController, decoration: const InputDecoration(labelText: 'URL Ảnh đại diện')),
                  const SizedBox(height: 16),
                  const Text('Danh mục cha:', style: TextStyle(fontSize: 12)),
                  DropdownButtonFormField<String>(
                    value: selectedParentId,
                    isExpanded: true,
                    hint: const Text('Là danh mục gốc'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Không có (Là danh mục gốc)'),
                      ),
                      ...allCategories
                          .where((c) => c.id != categoryToEdit?.id)
                          .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      ))
                    ],
                    onChanged: (value) => selectedParentId = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('HỦY')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  cubit.saveCategory(
                    existingCategory: categoryToEdit,
                    name: nameController.text.trim(),
                    imageUrl: imageUrlController.text.trim(),
                    parentId: selectedParentId,
                  );
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('LƯU'),
            ),
          ],
        );
      },
    );
  }
}