import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_products_cubit.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_product_form_page.dart';

class AdminProductsPage extends StatelessWidget {
  const AdminProductsPage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const AdminProductsPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdminProductsCubit>()..fetchAllProducts(),
      child: const AdminProductsView(),
    );
  }
}

class AdminProductsView extends StatelessWidget {
  const AdminProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Sản phẩm'),
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
              ),
              onChanged: (query) {
                context.read<AdminProductsCubit>().searchProducts(query);
              },
            ),
          ),
          // Danh sách sản phẩm
          Expanded(
            child: BlocBuilder<AdminProductsCubit, AdminProductsState>(
              builder: (context, state) {
                if (state.status == AdminProductsStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == AdminProductsStatus.error) {
                  return Center(child: Text(state.errorMessage ?? 'Lỗi tải dữ liệu'));
                }
                if (state.filteredProducts.isEmpty) {
                  return const Center(child: Text('Không tìm thấy sản phẩm nào.'));
                }

                return ListView.separated(
                  itemCount: state.filteredProducts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = state.filteredProducts[index];
                    return _buildProductListItem(context, product);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // SỬA LỖI Ở ĐÂY: Thêm <bool?> vào push
          Navigator.of(context).push<bool?>(AdminProductFormPage.route()).then((success) {
            if (success == true) {
              context.read<AdminProductsCubit>().fetchAllProducts();
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductListItem(BuildContext context, ProductModel product) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return ListTile(
      leading: (product.imageUrl.isNotEmpty)
          ? Image.network(product.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
          : Container(width: 50, height: 50, color: Colors.grey.shade200, child: const Icon(Icons.image)),
      title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('Giá: ${currencyFormatter.format(product.displayPrice)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueGrey),
            onPressed: () {
              // SỬA LỖI Ở ĐÂY: Thêm <bool?> vào push
              Navigator.of(context).push<bool?>(AdminProductFormPage.route(product: product)).then((success) {
                if (success == true) {
                  context.read<AdminProductsCubit>().fetchAllProducts();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
            onPressed: () {
              // Hiển thị dialog xác nhận xóa
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Xác nhận xóa'),
                  content: Text('Bạn có chắc chắn muốn xóa sản phẩm "${product.name}"?'),
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
    );
  }
}
