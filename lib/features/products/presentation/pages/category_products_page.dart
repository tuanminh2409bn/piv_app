import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/home/data/models/category_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/products/presentation/bloc/category_products_cubit.dart';
import 'package:piv_app/features/products/presentation/pages/product_detail_page.dart';
import 'package:intl/intl.dart';

class CategoryProductsPage extends StatelessWidget {
  final CategoryModel category;

  const CategoryProductsPage({super.key, required this.category});

  static PageRoute<void> route(CategoryModel category) {
    return MaterialPageRoute(builder: (_) => CategoryProductsPage(category: category));
  }

  @override
  Widget build(BuildContext context) {
    // Cung cấp một instance mới của CategoryProductsCubit và bắt đầu tải dữ liệu
    return BlocProvider(
      create: (_) => sl<CategoryProductsCubit>()..fetchDataForCategory(category),
      child: const CategoryProductsView(),
    );
  }
}

class CategoryProductsView extends StatelessWidget {
  const CategoryProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Lấy tên danh mục hiện tại từ state để làm tiêu đề
        title: BlocBuilder<CategoryProductsCubit, CategoryProductsState>(
          builder: (context, state) {
            return Text(state.currentCategory?.name ?? 'Danh mục');
          },
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<CategoryProductsCubit, CategoryProductsState>(
        builder: (context, state) {
          // Xử lý các trạng thái khác nhau
          if (state.status == CategoryProductsStatus.loading || state.status == CategoryProductsStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == CategoryProductsStatus.error) {
            return Center(child: Text(state.errorMessage ?? 'Lỗi tải dữ liệu'));
          }

          bool hasSubCategories = state.subCategories.isNotEmpty;
          bool hasProducts = state.products.isNotEmpty;

          if (!hasSubCategories && !hasProducts) {
            return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('Danh mục này hiện chưa có sản phẩm hoặc danh mục con nào.', textAlign: TextAlign.center),
                )
            );
          }

          // Sử dụng ListView để có thể cuộn qua các section
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Section Danh mục con
              if (hasSubCategories) ...[
                Text(
                  'DANH MỤC CON',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade700, letterSpacing: 1.2),
                ),
                const SizedBox(height: 16),
                _buildSubCategoryGrid(context, state.subCategories),
                const SizedBox(height: 32),
              ],
              // Section Sản phẩm
              if (hasProducts) ...[
                Text(
                  'SẢN PHẨM',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade700, letterSpacing: 1.2),
                ),
                const SizedBox(height: 16),
                _buildProductList(context, state.products),
              ],
            ],
          );
        },
      ),
    );
  }

  // Widget hiển thị lưới các danh mục con
  Widget _buildSubCategoryGrid(BuildContext context, List<CategoryModel> subCategories) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // Hiển thị 3 cột
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8, // Điều chỉnh tỷ lệ để card cao hơn một chút
      ),
      itemCount: subCategories.length,
      itemBuilder: (context, index) {
        final subCategory = subCategories[index];
        return InkWell(
          onTap: () {
            // Đệ quy: Mở một trang CategoryProductsPage khác cho danh mục con này
            Navigator.of(context).push(CategoryProductsPage.route(subCategory));
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              Expanded(
                child: Card(
                  elevation: 3,
                  shadowColor: Colors.black.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    subCategory.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (c, e, s) => const Center(child: Icon(Icons.category_outlined, color: Colors.grey, size: 30)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subCategory.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: Colors.black87),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget hiển thị danh sách sản phẩm
  Widget _buildProductList(BuildContext context, List<ProductModel> products) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      separatorBuilder: (_, __) => const Divider(height: 24),
      itemBuilder: (context, index) {
        final product = products[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              product.imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (c,e,s) => Container(width: 70, height: 70, color: Colors.grey.shade200, child: const Icon(Icons.image_search_outlined, color: Colors.grey)),
            ),
          ),
          title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            '${currencyFormatter.format(product.displayPrice)} / ${product.unit}',
            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 18),
          onTap: () {
            Navigator.of(context).push(ProductDetailPage.route(product.id));
          },
        );
      },
    );
  }
}
