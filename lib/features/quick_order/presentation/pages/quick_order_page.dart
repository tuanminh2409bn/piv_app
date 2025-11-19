// lib/features/quick_order/presentation/pages/quick_order_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/cart_item_model.dart';
import 'package:piv_app/data/models/packaging_option_model.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:piv_app/features/checkout/presentation/pages/checkout_page.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/products/presentation/pages/product_detail_page.dart';
import 'package:piv_app/features/quick_order/domain/repositories/quick_order_repository.dart';
import 'package:piv_app/features/quick_order/presentation/bloc/quick_order_cubit.dart';

class QuickOrderPage extends StatelessWidget {
  final String? targetAgentId;   // ID để lấy danh sách sản phẩm
  final String? targetUserRole;  // Role để hiển thị đúng giá

  const QuickOrderPage({
    super.key,
    this.targetAgentId,
    this.targetUserRole,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuickOrderCubit(
        quickOrderRepository: sl<QuickOrderRepository>(),
        authBloc: context.read<AuthBloc>(),
        targetAgentId: targetAgentId,
      ),
      child: QuickOrderView(targetUserRole: targetUserRole),
    );
  }
}

class QuickOrderView extends StatelessWidget {
  final String? targetUserRole;

  const QuickOrderView({super.key, this.targetUserRole});

  @override
  Widget build(BuildContext context) {
    // Lấy kích thước màn hình để tính toán tỷ lệ khung hình động
    final screenWidth = MediaQuery.of(context).size.width;
    // Tính toán aspect ratio: Màn hình càng rộng thì thẻ càng nên bè ra một chút
    final double itemAspectRatio = (screenWidth / 2) / 320; // 320 là chiều cao ước tính của card

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Màu nền xám nhẹ cho sang trọng
      body: BlocBuilder<QuickOrderCubit, QuickOrderState>(
        builder: (context, state) {
          if (state.status == QuickOrderStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == QuickOrderStatus.error) {
            return Center(child: Text(state.errorMessage ?? 'Đã có lỗi xảy ra'));
          }
          if (state.products.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'Danh sách đặt hàng nhanh đang trống',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Vui lòng liên hệ NVKD hoặc công ty để được hỗ trợ thêm sản phẩm vào danh sách này.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              // Sử dụng tỷ lệ động hoặc cố định khoảng 0.6 - 0.65 cho cân đối
              childAspectRatio: 0.62,
            ),
            itemCount: state.products.length,
            itemBuilder: (context, index) {
              final product = state.products[index];
              return ProductGridItem(
                product: product,
                targetUserRole: targetUserRole,
              );
            },
          );
        },
      ),
    );
  }
}

class ProductGridItem extends StatelessWidget {
  final ProductModel product;
  final String? targetUserRole;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  ProductGridItem({
    super.key,
    required this.product,
    this.targetUserRole,
  });

  String _getEffectiveRole(BuildContext context) {
    if (targetUserRole != null) {
      return targetUserRole!;
    }
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.role;
    }
    return 'guest';
  }

  Future<CartItemModel?> _showPackagingOptionsDialog(BuildContext context) async {
    final effectiveRole = _getEffectiveRole(context);

    return showDialog<CartItemModel>(
      context: context,
      builder: (dialogContext) {
        if (product.packingOptions.isEmpty) {
          return AlertDialog(
            title: const Text('Thông báo'),
            content: const Text('Sản phẩm này chưa có quy cách đóng gói.'),
            actions: [TextButton(onPressed: ()=> Navigator.of(dialogContext).pop(), child: const Text('Đóng'))],
          );
        }

        PackagingOptionModel selectedOption = product.packingOptions.first;
        final quantityController = TextEditingController(text: '1');

        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Chọn quy cách cho ${product.name}', style: const TextStyle(fontSize: 18)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<PackagingOptionModel>(
                      value: selectedOption,
                      isExpanded: true,
                      items: product.packingOptions.map((option) {
                        final price = option.getPriceForRole(effectiveRole);
                        return DropdownMenuItem(
                          value: option,
                          child: Text('${option.name} - ${currencyFormatter.format(price)}', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) stfSetState(() => selectedOption = value);
                      },
                      decoration: InputDecoration(
                        labelText: 'Quy cách',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Số lượng',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: IconButton(
                            onPressed: () {
                              int current = int.tryParse(quantityController.text) ?? 0;
                              if(current > 1) quantityController.text = (current - 1).toString();
                            },
                            icon: const Icon(Icons.remove)
                        ),
                        suffixIcon: IconButton(
                            onPressed: () {
                              int current = int.tryParse(quantityController.text) ?? 0;
                              quantityController.text = (current + 1).toString();
                            },
                            icon: const Icon(Icons.add)
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(null), child: const Text('Hủy')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final quantity = int.tryParse(quantityController.text) ?? 0;
                    if (quantity > 0) {
                      final price = selectedOption.getPriceForRole(effectiveRole);
                      final cartItem = CartItemModel(
                        productId: product.id,
                        productName: product.name,
                        imageUrl: product.imageUrl,
                        price: price,
                        itemUnitName: selectedOption.unit,
                        quantity: quantity,
                        quantityPerPackage: selectedOption.quantityPerPackage,
                        caseUnitName: selectedOption.name,
                        categoryId: product.categoryId,
                      );
                      Navigator.of(dialogContext).pop(cartItem);
                    }
                  },
                  child: const Text('Xác nhận'),
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
    final effectiveRole = _getEffectiveRole(context);
    final displayPrice = product.getPriceForRole(effectiveRole);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(ProductDetailPage.route(product.id)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. PHẦN ẢNH SẢN PHẨM (TỶ LỆ 1:1) ---
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 1.0, // Ảnh luôn vuông
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade100,
                        child: Icon(Icons.image, size: 40, color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
                // Badge Sản phẩm riêng
                if (product.isPrivate)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('SẢN PHẨM ĐỘC QUYỀN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // --- 2. PHẦN THÔNG TIN ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên sản phẩm
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Giá sản phẩm
                    Text(
                      currencyFormatter.format(displayPrice),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),

                    const Spacer(), // Đẩy nút xuống dưới cùng

                    // --- 3. CÁC NÚT BẤM (NHỎ GỌN HƠN) ---
                    Row(
                      children: [
                        // Nút Mua ngay (Outlined)
                        Expanded(
                          child: SizedBox(
                            height: 32, // Chiều cao nhỏ gọn
                            child: OutlinedButton(
                              onPressed: () async {
                                final cartItem = await _showPackagingOptionsDialog(context);
                                if (cartItem != null && context.mounted) {
                                  Navigator.of(context).push(CheckoutPage.route(buyNowItems: [cartItem]));
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                              ),
                              child: const Text('Mua', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Nút Thêm vào giỏ (Filled Icon)
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton.filled(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.add_shopping_cart, size: 16),
                            onPressed: () async {
                              final cartItem = await _showPackagingOptionsDialog(context);
                              if (cartItem != null && context.mounted) {
                                context.read<CartCubit>().addProduct(
                                  product: product,
                                  selectedOption: product.packingOptions.firstWhere((opt) => opt.name == cartItem.caseUnitName),
                                  quantity: cartItem.quantity,
                                );
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(SnackBar(content: Text('Đã thêm ${product.name} vào giỏ hàng')));
                              }
                            },
                            style: IconButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}