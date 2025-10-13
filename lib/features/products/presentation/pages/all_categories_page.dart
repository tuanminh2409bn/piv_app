import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:piv_app/features/products/presentation/pages/category_products_page.dart';

class AllCategoriesPage extends StatelessWidget {
  const AllCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Trang này không cần Scaffold hay AppBar vì nó là một phần của MainScreen.
    // Nó sử dụng HomeCubit được cung cấp bởi MainScreen (widget cha).
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        // Hiển thị vòng tròn tải khi dữ liệu chưa sẵn sàng
        if (state.status == HomeStatus.loading || state.status == HomeStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }
        // Hiển thị lỗi nếu có
        if (state.status == HomeStatus.error) {
          return Center(child: Text(state.errorMessage ?? 'Lỗi tải danh mục'));
        }

        // Lọc để chỉ lấy các danh mục gốc (cấp 1) từ danh sách đầy đủ
        final topLevelCategories = state.allCategories.where((c) => c.parentId == null).toList();

        // Hiển thị thông báo nếu không có danh mục nào
        if (topLevelCategories.isEmpty) {
          return const Center(child: Text('Không có danh mục nào.'));
        }

        // Sử dụng GridView để hiển thị các danh mục một cách đẹp mắt
        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 cột
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1, // Card hình vuông để cân đối
          ),
          itemCount: topLevelCategories.length,
          itemBuilder: (context, index) {
            final category = topLevelCategories[index];
            return InkWell(
              onTap: () {
                // Khi nhấn vào, điều hướng đến trang danh sách sản phẩm/danh mục con
                Navigator.of(context).push(CategoryProductsPage.route(category));
              },
              borderRadius: BorderRadius.circular(12),
              child: Card(
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias, // Đảm bảo ảnh được bo góc theo Card
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Phần ảnh
                    Expanded(
                      flex: 3,
                      child: Image.network(
                        category.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Center(
                            child: Icon(Icons.category, size: 40, color: Colors.grey)
                        ),
                      ),
                    ),
                    // Phần tên danh mục
                    Expanded(
                      flex: 2,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          category.name,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}