// lib/features/quick_order/presentation/pages/quick_order_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/core/theme/nature_background_painter.dart';
import 'package:piv_app/data/models/cart_item_model.dart';
import 'package:piv_app/data/models/packaging_option_model.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:piv_app/features/checkout/presentation/pages/checkout_page.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/products/presentation/pages/product_detail_page.dart';
import 'package:piv_app/features/quick_order/domain/repositories/quick_order_repository.dart';
import 'package:piv_app/features/quick_order/presentation/bloc/quick_order_cubit.dart';
import 'package:piv_app/features/auth/presentation/pages/login_page.dart';

class QuickOrderPage extends StatelessWidget {
  final String? targetAgentId;
  final String? targetUserRole;

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
    final screenWidth = MediaQuery.of(context).size.width;
    final double childAspectRatio = (screenWidth / 2) / 300; 

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          // Background Patterns
          Positioned.fill(
            child: CustomPaint(
              painter: NatureBackgroundPainter(
                color1: AppTheme.primaryGreen.withValues(alpha: 0.05),
                color2: AppTheme.secondaryGreen.withValues(alpha: 0.03),
                accent: AppTheme.accentGold.withValues(alpha: 0.1),
              ),
            ),
          ),

          BlocBuilder<QuickOrderCubit, QuickOrderState>(
            builder: (context, state) {
              if (state.status == QuickOrderStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == QuickOrderStatus.error) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                      const SizedBox(height: 16),
                      Text(state.errorMessage ?? 'Đã có lỗi xảy ra', style: const TextStyle(color: AppTheme.textGrey)),
                    ],
                  ),
                );
              }
              if (state.products.isEmpty) {
                return _buildEmptyState();
              }

              return CustomScrollView(
                slivers: [
                  // SliverAppBar đồng bộ với các trang khác
                  SliverAppBar(
                    expandedHeight: 140.0,
                    pinned: true,
                    backgroundColor: AppTheme.primaryGreen,
                    automaticallyImplyLeading: false, // Vì trang này nằm trong MainScreen tab
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: false,
                      titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                      title: const Text(
                        'Đặt hàng nhanh',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      background: Stack(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.primaryGreen, AppTheme.secondaryGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: NatureBackgroundPainter(
                                color1: Colors.white.withValues(alpha: 0.1),
                                color2: Colors.white.withValues(alpha: 0.05),
                                accent: AppTheme.accentGold.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.all(12.0),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: childAspectRatio,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = state.products[index];
                          return ProductGridItem(
                            product: product,
                            targetUserRole: targetUserRole,
                            index: index,
                          );
                        },
                        childCount: state.products.length,
                      ),
                    ),
                  ),
                  // Tăng chiều cao lên 120 để tránh bottom nav bar của MainScreen (80px + padding)
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ).animate().fadeIn(duration: 400.ms);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 80, color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
            const SizedBox(height: 24),
            const Text(
              'Danh sách trống',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),
            const Text(
              'Vui lòng liên hệ NVKD hoặc công ty để được hỗ trợ thêm sản phẩm vào danh sách này.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductGridItem extends StatelessWidget {
  final ProductModel product;
  final String? targetUserRole;
  final int index;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  ProductGridItem({
    super.key,
    required this.product,
    this.targetUserRole,
    required this.index,
  });

  String _getEffectiveRole(BuildContext context) {
    if (targetUserRole != null) return targetUserRole!;
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated ? authState.user.role : 'guest';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRole = _getEffectiveRole(context);
    final displayPrice = product.getPriceForRole(effectiveRole);
    final authState = context.watch<AuthBloc>().state;
    bool canViewPrice = false;
    if (authState is AuthAuthenticated) {
      if (!authState.user.isGuest && authState.user.status == 'active') canViewPrice = true;
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).push(ProductDetailPage.route(product.id)),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade100, child: const Icon(Icons.image, size: 40, color: Colors.grey)),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (canViewPrice)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              currencyFormatter.format(displayPrice),
                              style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Material(
                            color: AppTheme.secondaryGreen,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () async => _handleAddToCart(context, product, effectiveRole),
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Icon(Icons.add_shopping_cart, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: FittedBox(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pushAndRemoveUntil(LoginPage.route(), (route) => false),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            child: const Text('Đăng nhập xem giá', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 11, fontStyle: FontStyle.italic)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (50 * (index % 6)).ms).slideY(begin: 0.1, end: 0);
  }

  Future<void> _handleAddToCart(BuildContext context, ProductModel product, String userRole) async {
    final cartItem = await _showPackagingOptionsDialog(context, product, userRole);
    if (cartItem != null && context.mounted) {
      context.read<CartCubit>().addProduct(
        product: product,
        selectedOption: product.packingOptions.firstWhere((opt) => opt.name == cartItem.caseUnitName),
        quantity: cartItem.quantity,
      );
      ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text('Đã thêm ${product.name} vào giỏ hàng'), backgroundColor: AppTheme.secondaryGreen, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16)));
    }
  }

  Future<CartItemModel?> _showPackagingOptionsDialog(BuildContext context, ProductModel product, String userRole) async {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
     return showDialog<CartItemModel>(
      context: context,
      builder: (dialogContext) {
        if (product.packingOptions.isEmpty) {
          return AlertDialog(
            title: const Text('Thông báo'), 
            content: const Text('Sản phẩm này chưa có quy cách đóng gói.'), 
            actions: [TextButton(onPressed: ()=> Navigator.of(dialogContext).pop(), child: const Text('Đóng'))]
          );
        }
        PackagingOptionModel selectedOption = product.packingOptions.first;
        final quantityController = TextEditingController(text: '1');
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Chọn mua ${product.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView( 
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quy cách đóng gói:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    ...product.packingOptions.map((option) {
                      final bool isRetail = option.quantityPerPackage == 1;
                      final String typeLabel = isRetail ? 'MUA LẺ' : 'MUA THÙNG';
                      final String subLabel = isRetail 
                          ? 'Đơn vị: ${option.unit}' 
                          : 'Quy cách: ${option.name} (${option.quantityPerPackage} ${option.unit})';
                      final price = option.getPriceForRole(userRole);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedOption == option ? AppTheme.primaryGreen : Colors.grey.shade300,
                            width: selectedOption == option ? 2 : 1,
                          ),
                          color: selectedOption == option ? AppTheme.primaryGreen.withValues(alpha: 0.05) : Colors.transparent,
                        ),
                        child: RadioListTile<PackagingOptionModel>(
                          value: option,
                          groupValue: selectedOption,
                          activeColor: AppTheme.primaryGreen,
                          onChanged: (value) { if (value != null) stfSetState(() => selectedOption = value); },
                          title: Text(typeLabel, style: TextStyle(fontWeight: FontWeight.bold, color: selectedOption == option ? AppTheme.primaryGreen : AppTheme.textDark, fontSize: 14)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(subLabel, style: const TextStyle(fontSize: 12)),
                              Text(currencyFormatter.format(price), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13)),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    const Text('Số lượng đặt:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: quantityController, 
                      keyboardType: TextInputType.number, 
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        prefixIcon: IconButton(onPressed: () { int current = int.tryParse(quantityController.text) ?? 0; if(current > 1) stfSetState(() => quantityController.text = (current - 1).toString()); }, icon: const Icon(Icons.remove_circle_outline)),
                        suffixIcon: IconButton(onPressed: () { int current = int.tryParse(quantityController.text) ?? 0; stfSetState(() => quantityController.text = (current + 1).toString()); }, icon: const Icon(Icons.add_circle_outline)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(null), child: const Text('Hủy', style: TextStyle(color: AppTheme.textGrey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    final quantity = int.tryParse(quantityController.text) ?? 0;
                    if (quantity > 0) {
                      final price = selectedOption.getPriceForRole(userRole);
                      Navigator.of(dialogContext).pop(CartItemModel(
                        productId: product.id, 
                        productName: product.name, 
                        imageUrl: product.imageUrl, 
                        price: price, 
                        itemUnitName: selectedOption.unit, 
                        quantity: quantity, 
                        quantityPerPackage: selectedOption.quantityPerPackage, 
                        caseUnitName: selectedOption.name, 
                        categoryId: product.categoryId
                      ));
                    }
                  },
                  child: const Text('XÁC NHẬN', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
