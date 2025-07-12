// lib/features/admin/presentation/pages/admin_products_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_products_cubit.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_product_form_page.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';

class AdminProductsPage extends StatelessWidget {
  const AdminProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Cung cấp Cubit cho riêng trang này
    return BlocProvider(
      create: (_) => sl<AdminProductsCubit>()..fetchAllProducts(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý Sản phẩm'),
        ),
        // Trang này sẽ có nút FloatingActionButton riêng
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push<bool?>(AdminProductFormPage.route()).then((success) {
              if (success == true) {
                context.read<AdminProductsCubit>().fetchAllProducts();
              }
            });
          },
          child: const Icon(Icons.add),
        ),
        body: const AdminProductsView(), // Gọi đến View đã được di chuyển
      ),
    );
  }
}


// =================================================================
//        WIDGET VIEW ĐÃ ĐƯỢC DI CHUYỂN TỪ TRANG HOME
// =================================================================
class AdminProductsView extends StatelessWidget {
  const AdminProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Tìm kiếm sản phẩm...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (query) => context.read<AdminProductsCubit>().searchProducts(query),
          ),
        ),
        Expanded(
          child: BlocBuilder<AdminProductsCubit, AdminProductsState>(
            builder: (context, state) {
              if (state.status == AdminProductsStatus.loading && state.filteredProducts.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.filteredProducts.isEmpty) {
                return const Center(child: Text('Không tìm thấy sản phẩm nào.'));
              }
              return RefreshIndicator(
                onRefresh: () => context.read<AdminProductsCubit>().fetchAllProducts(),
                child: ListView.separated(
                  itemCount: state.filteredProducts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = state.filteredProducts[index];
                    return _buildProductListItem(context, product);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductListItem(BuildContext context, ProductModel product) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final displayPrice = product.packingOptions.isNotEmpty && product.packingOptions.first.prices.isNotEmpty
        ? product.packingOptions.first.prices.values.first
        : 0.0;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push<bool?>(AdminProductFormPage.route(product: product)).then((success) {
            if (success == true) {
              context.read<AdminProductsCubit>().fetchAllProducts();
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 8.0, 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: (product.imageUrl.isNotEmpty)
                    ? Image.network(product.imageUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported)))
                    : Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.image)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis,),
                    const SizedBox(height: 4),
                    Text('Giá từ: ${currencyFormatter.format(displayPrice)}'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Nổi bật', style: TextStyle(fontSize: 10)),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: product.isFeatured,
                      onChanged: (newValue) {
                        context.read<AdminProductsCubit>().toggleIsFeatured(product.id, product.isFeatured);
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                tooltip: 'Xóa sản phẩm',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Xác nhận xóa'),
                      content: Text('Bạn có chắc chắn muốn xóa sản phẩm "${product.name}"? Hành động này không thể hoàn tác.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Hủy')),
                        TextButton(
                          onPressed: () {
                            context.read<AdminProductsCubit>().deleteProduct(product.id);
                            Navigator.of(dialogContext).pop();
                          },
                          child: Text('Xóa', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}