import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_categories_cubit.dart';
import 'package:piv_app/features/home/data/models/category_model.dart';

class AdminCategoriesPage extends StatelessWidget {
  const AdminCategoriesPage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const AdminCategoriesPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdminCategoriesCubit>()..fetchAllCategories(),
      child: const AdminCategoriesView(),
    );
  }
}

class AdminCategoriesView extends StatelessWidget {
  const AdminCategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Danh mục'),
      ),
      body: BlocBuilder<AdminCategoriesCubit, AdminCategoriesState>(
        builder: (context, state) {
          if (state.status == AdminCategoriesStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == AdminCategoriesStatus.error) {
            return Center(child: Text(state.errorMessage ?? 'Lỗi tải dữ liệu'));
          }

          final topLevelCategories = state.topLevelCategories;

          if (topLevelCategories.isEmpty) {
            return const Center(child: Text('Chưa có danh mục nào.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AdminCategoriesCubit>().fetchAllCategories();
            },
            child: ListView(
              padding: const EdgeInsets.all(8.0),
              children: topLevelCategories.map((category) {
                // Bắt đầu cây danh mục với cấp độ 0
                return _buildCategoryTree(context, category, state.allCategories, 0);
              }).toList(),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Mở form để thêm danh mục gốc (parentId = null)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chức năng Thêm danh mục sẽ được làm sau!')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // ** HÀM XÂY DỰNG CÂY DANH MỤC ĐÃ ĐƯỢC SỬA LẠI LOGIC THỤT LỀ **
  Widget _buildCategoryTree(BuildContext context, CategoryModel category, List<CategoryModel> allCategories, int level) {
    final subCategories = allCategories.where((c) => c.parentId == category.id).toList();
    final bool hasChildren = subCategories.isNotEmpty;

    // Xác định khoảng cách thụt lề cho mỗi cấp
    const double indentationStep = 20.0;

    // Nếu danh mục có con, dùng ExpansionTile
    if (hasChildren) {
      return ExpansionTile(
        // Thụt lề cho toàn bộ tile dựa trên cấp độ
        tilePadding: EdgeInsets.only(left: indentationStep * level, right: 16.0),
        // Các thuộc tính khác của ExpansionTile
        leading: Icon(Icons.folder_open_rounded, color: Colors.amber.shade800),
        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        // Children sẽ được gọi đệ quy với cấp độ tăng lên, tự động thụt lề
        children: subCategories.map((sub) {
          return _buildCategoryTree(context, sub, allCategories, level + 1);
        }).toList(),
      );
    }
    // Nếu là danh mục lá (không có con), dùng ListTile
    else {
      return ListTile(
        // Thụt lề cho ListTile. Thêm một chút để thẳng hàng với text của ExpansionTile
        contentPadding: EdgeInsets.only(left: (indentationStep * level) + 16.0, right: 16.0),
        leading: Icon(Icons.article_outlined, color: Colors.grey.shade600, size: 20),
        title: Text(category.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.edit, size: 20, color: Colors.blueGrey),
              onPressed: () {
                // TODO: Mở form sửa danh mục
              },
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.delete, size: 20, color: Theme.of(context).colorScheme.error),
              onPressed: () {
                // TODO: Xử lý xóa danh mục
              },
            ),
          ],
        ),
      );
    }
  }
}
