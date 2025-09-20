// lib/features/products/presentation/pages/category_products_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/home/data/models/category_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/products/presentation/bloc/category_products_cubit.dart';
import 'package:piv_app/features/products/presentation/pages/product_detail_page.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:intl/intl.dart';

class CategoryProductsPage extends StatelessWidget {
  final CategoryModel category;

  const CategoryProductsPage({super.key, required this.category});

  static PageRoute<void> route(CategoryModel category) {
    return MaterialPageRoute(builder: (_) => CategoryProductsPage(category: category));
  }

  @override
  Widget build(BuildContext context) {
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
    final authState = context.watch<AuthBloc>().state;
    String userRole = 'guest';
    bool canViewPrice = false;

    if (authState is AuthAuthenticated) {
      final user = authState.user;
      userRole = user.role;
      if (!user.isGuest && user.status == 'active') {
        canViewPrice = true;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<CategoryProductsCubit, CategoryProductsState>(
          builder: (context, state) {
            return Text(state.currentCategory?.name ?? 'Danh mục');
          },
        ),
      ),
      body: BlocBuilder<CategoryProductsCubit, CategoryProductsState>(
        builder: (context, state) {
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

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (hasSubCategories) ...[
                Text(
                  'DANH MỤC CON',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                _buildSubCategoryGrid(context, state.subCategories),
                const SizedBox(height: 24),
              ],
              if (hasProducts) ...[
                Text(
                  'SẢN PHẨM',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                _buildProductList(context, state.products, userRole, canViewPrice),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSubCategoryGrid(BuildContext context, List<CategoryModel> subCategories) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: subCategories.length,
      itemBuilder: (context, index) {
        final subCategory = subCategories[index];
        return InkWell(
          onTap: () {
            Navigator.of(context).push(CategoryProductsPage.route(subCategory));
          },
          borderRadius: BorderRadius.circular(8),
          child: Column(
            children: [
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(subCategory.imageUrl, fit: BoxFit.cover, width: double.infinity, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.category, color: Colors.grey))),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subCategory.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- HÀM NÀY ĐÃ ĐƯỢC SỬA ---
  Widget _buildProductList(BuildContext context, List<ProductModel> products, String userRole, bool canViewPrice) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final product = products[index];
        final price = product.getPriceForRole(userRole);
        final unit = product.displayUnit;
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: (product.imageUrl.isNotEmpty)
                ? Image.network(product.imageUrl, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(width: 70, height: 70, color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)))
                : Container(width: 70, height: 70, color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)),
          ),
          title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          // --- HIỂN THỊ GIÁ CÓ ĐIỀU KIỆN ---
          subtitle: canViewPrice
              ? Text(
            '${currencyFormatter.format(price)} / $unit',
            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
          )
              : Text(
            'Đăng nhập để xem giá',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          // ------------------------------------
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.of(context).push(ProductDetailPage.route(product.id));
          },
        );
      },
    );
  }
}