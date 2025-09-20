// lib/features/quick_order/presentation/pages/quick_order_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/packaging_option_model.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/products/presentation/pages/product_detail_page.dart';
import 'package:piv_app/features/quick_order/domain/repositories/quick_order_repository.dart';
import 'package:piv_app/features/quick_order/presentation/bloc/quick_order_cubit.dart';

class QuickOrderPage extends StatelessWidget {
  const QuickOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuickOrderCubit(
        quickOrderRepository: sl<QuickOrderRepository>(),
        authBloc: context.read<AuthBloc>(),
      ),
      child: const QuickOrderView(),
    );
  }
}

class QuickOrderView extends StatelessWidget {
  const QuickOrderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<QuickOrderCubit, QuickOrderState>(
        builder: (context, state) {
          if (state.status == QuickOrderStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == QuickOrderStatus.error) {
            return Center(child: Text(state.errorMessage ?? 'Đã có lỗi xảy ra'));
          }
          if (state.products.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Danh sách đặt hàng nhanh của bạn đang trống.\n'
                      'Vui lòng liên hệ NVKD hoặc công ty để được hỗ trợ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: state.products.length,
            itemBuilder: (context, index) {
              final product = state.products[index];
              return ProductGridItem(product: product);
            },
          );
        },
      ),
    );
  }
}

class ProductGridItem extends StatelessWidget {
  final ProductModel product;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  ProductGridItem({super.key, required this.product});

  Future<void> _showPackagingOptionsDialog(BuildContext context) async {
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    final agentRole = user.role;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        if (product.packingOptions.isEmpty) {
          return AlertDialog(
            title: const Text('Lỗi sản phẩm'),
            content: const Text('Sản phẩm này chưa có quy cách đóng gói.'),
            actions: [TextButton(onPressed: ()=> Navigator.of(dialogContext).pop(), child: const Text('Đã hiểu'))],
          );
        }

        PackagingOptionModel selectedOption = product.packingOptions.first;
        final quantityController = TextEditingController(text: '1');

        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            return AlertDialog(
              title: Text('Chọn quy cách cho ${product.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<PackagingOptionModel>(
                      value: selectedOption,
                      isExpanded: true,
                      items: product.packingOptions.map((option) {
                        final price = option.getPriceForRole(agentRole);
                        return DropdownMenuItem(
                          value: option,
                          child: Text('${option.name} - ${currencyFormatter.format(price)}', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) stfSetState(() => selectedOption = value);
                      },
                      decoration: const InputDecoration(labelText: 'Quy cách', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Số lượng', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('HỦY')),
                ElevatedButton(
                  onPressed: () {
                    final quantity = int.tryParse(quantityController.text) ?? 0;
                    if (quantity > 0) {
                      // <<< SỬA LỖI DUY NHẤT TẠI ĐÂY >>>
                      // Gọi đúng tên hàm là `addProduct` thay vì `addToCart`
                      context.read<CartCubit>().addProduct(
                        product: product,
                        selectedOption: selectedOption,
                        quantity: quantity,
                      );

                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(content: Text('Đã thêm ${product.name} vào giỏ hàng')));

                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('THÊM VÀO GIỎ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    final displayPrice = product.getPriceForRole(user.role);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(ProductDetailPage.route(product.id)),
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(displayPrice),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const Text('Thêm vào giỏ'),
                style: ElevatedButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                onPressed: () => _showPackagingOptionsDialog(context),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}