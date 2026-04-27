// lib/features/products/presentation/pages/category_products_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/common/widgets/app_network_image.dart';
import 'package:piv_app/common/widgets/responsive_wrapper.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/core/theme/nature_background_painter.dart';
import 'package:piv_app/core/utils/responsive.dart';
import 'package:piv_app/features/home/data/models/category_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/products/presentation/bloc/category_products_cubit.dart';
import 'package:piv_app/features/products/presentation/pages/product_detail_page.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/auth/presentation/pages/login_page.dart';
import 'package:piv_app/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:piv_app/features/cart/presentation/pages/cart_page.dart';
import 'package:piv_app/features/cart/presentation/widgets/cart_icon_with_badge.dart';
import 'package:piv_app/data/models/cart_item_model.dart';
import 'package:piv_app/data/models/packaging_option_model.dart';

class CategoryProductsPage extends StatelessWidget {
  final CategoryModel category;

  const CategoryProductsPage({super.key, required this.category});

  static PageRoute<void> route(CategoryModel category) {
    return MaterialPageRoute(builder: (_) => CategoryProductsPage(category: category));
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    String? userId;
    if (authState is AuthAuthenticated) userId = authState.user.id;

    return BlocProvider(
      create: (_) => sl<CategoryProductsCubit>()..fetchDataForCategory(category, currentUserId: userId),
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
      userRole = authState.user.role;
      if (!authState.user.isGuest && authState.user.status == 'active') canViewPrice = true;
    }

    final int subCatCrossAxisCount = Responsive.value(context, mobile: 2, desktop: 4);
    final int prodCrossAxisCount = Responsive.value(context, mobile: 2, desktop: 4);
    final double prodChildAspectRatio = Responsive.value(
      context, 
      mobile: (MediaQuery.of(context).size.width / 2) / 300,
      desktop: 0.65,
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: NatureBackgroundPainter(
                color1: AppTheme.primaryGreen.withValues(alpha: 0.05),
                color2: AppTheme.secondaryGreen.withValues(alpha: 0.03),
                accent: AppTheme.accentGold.withValues(alpha: 0.1),
              ),
            ),
          ),

          BlocBuilder<CategoryProductsCubit, CategoryProductsState>(
            builder: (context, state) {
              if (state.status == CategoryProductsStatus.loading || state.status == CategoryProductsStatus.initial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == CategoryProductsStatus.error) {
                return Center(child: Text(state.errorMessage ?? 'Lỗi tải dữ liệu', style: const TextStyle(color: AppTheme.textGrey)));
              }

              final hasSubCategories = state.subCategories.isNotEmpty;
              final hasProducts = state.products.isNotEmpty;

              final double screenWidth = MediaQuery.of(context).size.width;
              final double horizontalPadding = screenWidth > 1200 ? (screenWidth - 1200) / 2 + 16 : 16.0;

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 140.0,
                    pinned: true,
                    backgroundColor: AppTheme.primaryGreen,
                    leading: const BackButton(color: Colors.white),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        child: CartIconWithBadge(
                          iconColor: Colors.white,
                          onPressed: () => Navigator.of(context).push(CartPage.route()),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: false,
                      titlePadding: EdgeInsets.only(left: horizontalPadding > 16.0 ? horizontalPadding + 40 : 56, bottom: 16),
                      title: Text(
                        state.currentCategory?.name ?? 'Danh mục',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
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

                  // --- DANH MỤC CON (Nâng cấp to và đẹp như danh mục cha) ---
                  if (hasSubCategories) ...[
                    _buildSectionTitle('DANH MỤC CON', horizontalPadding),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: subCatCrossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85, // Đồng bộ tỷ lệ với danh mục cha
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _SubCategoryCard(category: state.subCategories[index], index: index),
                          childCount: state.subCategories.length,
                        ),
                      ),
                    ),
                  ],

                  // --- SẢN PHẨM ---
                  if (hasProducts) ...[
                    _buildSectionTitle('SẢN PHẨM', horizontalPadding),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: prodCrossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: prodChildAspectRatio,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _ProductCard(
                            product: state.products[index], 
                            userRole: userRole, 
                            canViewPrice: canViewPrice,
                            index: index,
                          ),
                          childCount: state.products.length,
                        ),
                      ),
                    ),
                  ],
                  SliverToBoxAdapter(child: SizedBox(height: 40 + MediaQuery.of(context).padding.bottom)),
                ],
              ).animate().fadeIn(duration: 400.ms);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, double horizontalPadding) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 12),
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textGrey, letterSpacing: 1.2),
        ),
      ),
    );
  }
}

class _SubCategoryCard extends StatelessWidget {
  final CategoryModel category;
  final int index;
  const _SubCategoryCard({required this.category, required this.index});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(CategoryProductsPage.route(category)),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ảnh danh mục
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  color: AppTheme.backgroundLight,
                  child: Image.network(
                    category.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Center(
                      child: Icon(Icons.spa_outlined, size: 40, color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
              ),
            ),
            // Tên danh mục (Căn giữa và có gạch chân vàng)
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 4,
                      width: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.1, end: 0);
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final String userRole;
  final bool canViewPrice;
  final int index;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  _ProductCard({required this.product, required this.userRole, required this.canViewPrice, required this.index});

  @override
  Widget build(BuildContext context) {
    final price = product.getPriceForRole(userRole);

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
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AppNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorWidget: Container(color: Colors.grey.shade100, child: const Icon(Icons.image, size: 40, color: Colors.grey)),
                    ),
                  ),
                  if (product.isPrivate)
                    Positioned(
                      top: 0, left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: const BoxDecoration(color: Colors.red, borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomRight: Radius.circular(12))),
                        child: const Text('ĐỘC QUYỀN', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
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
                              currencyFormatter.format(price),
                              style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Material(
                            color: AppTheme.secondaryGreen,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () async => _handleAddToCart(context),
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(padding: EdgeInsets.all(6.0), child: Icon(Icons.add_shopping_cart, color: Colors.white, size: 18)),
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

  Future<void> _handleAddToCart(BuildContext context) async {
    final cartItem = await _showOptions(context);
    if (cartItem != null && context.mounted) {
      context.read<CartCubit>().addProduct(product: product, selectedOption: product.packingOptions.firstWhere((opt) => opt.name == cartItem.caseUnitName), quantity: cartItem.quantity);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã thêm ${product.name} vào giỏ hàng'), backgroundColor: AppTheme.secondaryGreen, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16)));
    }
  }

  Future<CartItemModel?> _showOptions(BuildContext context) async {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return showDialog<CartItemModel>(
      context: context,
      builder: (dialogContext) {
        if (product.packingOptions.isEmpty) return AlertDialog(title: const Text('Thông báo'), content: const Text('Chưa có quy cách.'), actions: [TextButton(onPressed: ()=> Navigator.pop(dialogContext), child: const Text('Đóng'))]);
        PackagingOptionModel sel = product.packingOptions.first;
        final qty = TextEditingController(text: '1');
        return StatefulBuilder(builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<PackagingOptionModel>(value: sel, items: product.packingOptions.map((o) => DropdownMenuItem(value: o, child: Text('${o.name} - ${currencyFormatter.format(o.getPriceForRole(userRole))}', style: const TextStyle(fontSize: 13)))).toList(), onChanged: (v) => setState(() => sel = v!), decoration: const InputDecoration(labelText: 'Quy cách')),
            const SizedBox(height: 16),
            TextField(controller: qty, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: InputDecoration(labelText: 'Số lượng', prefixIcon: IconButton(onPressed: () { int c = int.tryParse(qty.text) ?? 0; if(c > 1) qty.text = (c - 1).toString(); }, icon: const Icon(Icons.remove)), suffixIcon: IconButton(onPressed: () { int c = int.tryParse(qty.text) ?? 0; qty.text = (c + 1).toString(); }, icon: const Icon(Icons.add)))),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')), ElevatedButton(onPressed: () { int q = int.tryParse(qty.text) ?? 0; if(q > 0) Navigator.pop(dialogContext, CartItemModel(productId: product.id, productName: product.name, imageUrl: product.imageUrl, price: sel.getPriceForRole(userRole), itemUnitName: sel.unit, quantity: q, quantityPerPackage: sel.quantityPerPackage, caseUnitName: sel.name, categoryId: product.categoryId)); }, child: const Text('XÁC NHẬN'))],
        ));
      },
    );
  }
}