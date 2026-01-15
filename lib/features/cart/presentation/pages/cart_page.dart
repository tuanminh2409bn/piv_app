// lib/features/cart/presentation/pages/cart_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/core/theme/nature_background_painter.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:piv_app/data/models/cart_item_model.dart';
import 'package:piv_app/features/checkout/presentation/pages/checkout_page.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/products/presentation/pages/product_detail_page.dart';
import '../bloc/cart_suggestions_cubit.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const CartPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CartSuggestionsCubit>(),
      child: const CartView(),
    );
  }
}

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: NatureBackgroundPainter(
                color1: AppTheme.primaryGreen.withValues(alpha: 0.05),
                color2: AppTheme.secondaryGreen.withValues(alpha: 0.03),
                accent: AppTheme.accentGold.withValues(alpha: 0.1),
              ),
            ),
          ),

          BlocListener<CartCubit, CartState>(
            listener: (context, state) {
              if (state.status == CartStatus.itemRemovedSuccess) {
                ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('Đã xoá sản phẩm khỏi giỏ hàng.'), backgroundColor: AppTheme.errorRed));
              } else if (state.status == CartStatus.itemAddedSuccess) {
                ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('Đã cập nhật giỏ hàng!'), backgroundColor: AppTheme.secondaryGreen));
              } else if (state.status == CartStatus.error && state.errorMessage != null) {
                ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(state.errorMessage!), backgroundColor: AppTheme.errorRed));
              }
            },
            child: BlocBuilder<CartCubit, CartState>(
              builder: (context, state) {
                if (state.status == CartStatus.loading && state.items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.items.isEmpty) {
                  return _buildEmptyCart(context);
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if(state.items.isNotEmpty) {
                    final lastItem = state.items.last;
                    context.read<CartSuggestionsCubit>().fetchSuggestions(lastItem.categoryId, currentProductId: lastItem.productId);
                  }
                });

                return Stack(
                  children: [
                    CustomScrollView(
                      slivers: [
                        _buildSliverAppBar(context, state.uniqueItemCount),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = state.items[index];
                                return _buildCartItemCard(context, item, currencyFormatter, index);
                              },
                              childCount: state.items.length,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(child: _buildSuggestionsSection()),
                        const SliverPadding(padding: EdgeInsets.only(bottom: 120)), // Space for bottom bar
                      ],
                    ),
                    _buildSummarySection(context, state, currencyFormatter),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, int itemCount) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: AppTheme.primaryGreen,
      leading: const BackButton(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text('Giỏ hàng ($itemCount)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.primaryGreen, AppTheme.secondaryGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(color: AppTheme.backgroundLight, shape: BoxShape.circle),
                child: Icon(Icons.shopping_cart_outlined, size: 80, color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 24),
              Text('Giỏ hàng trống trơn', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 8),
              const Text('Có vẻ như bạn chưa chọn sản phẩm nào.\nHãy dạo một vòng và thêm món đồ ưng ý nhé!', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textGrey)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.storefront),
                label: const Text('TIẾP TỤC MUA SẮM'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, CartItemModel item, NumberFormat formatter, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Dismissible(
        key: Key(item.productId + item.caseUnitName),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20.0),
          color: AppTheme.errorRed,
          child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
        ),
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Xác nhận xoá"),
                content: const Text("Bạn có chắc chắn muốn xoá sản phẩm này khỏi giỏ hàng?"),
                actions: <Widget>[
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("HỦY")),
                  TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("XOÁ", style: TextStyle(color: Colors.red))),
                ],
              );
            },
          );
        },
        onDismissed: (direction) {
          context.read<CartCubit>().removeProduct(item.productId, item.caseUnitName);
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              // Product Image
              InkWell(
                onTap: () => Navigator.of(context).push(ProductDetailPage.route(item.productId)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.imageUrl, width: 90, height: 90, fit: BoxFit.cover,
                      errorBuilder: (c,e,s) => Container(width:90, height:90, color: Colors.grey.shade100, child: const Icon(Icons.image_not_supported, color: Colors.grey)),
                    ),
                  ),
                ),
              ),
              
              // Product Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.productName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () => context.read<CartCubit>().removeProduct(item.productId, item.caseUnitName),
                            child: const Icon(Icons.close, size: 20, color: AppTheme.textGrey),
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(item.caseUnitName, style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatter.format(item.subtotal),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 16),
                          ),
                          _buildQuantityAdjuster(context, item),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideX();
  }

  Widget _buildQuantityAdjuster(BuildContext context, CartItemModel item) {
    final cartStatus = context.watch<CartCubit>().state.status;
    final bool isUpdatingThisItem = cartStatus == CartStatus.itemUpdating;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAdjustButton(
            icon: Icons.remove,
            onPressed: (item.quantity > 1 && !isUpdatingThisItem)
                ? () => context.read<CartCubit>().updateQuantity(item.productId, item.caseUnitName, item.quantity - 1)
                : null,
          ),
          GestureDetector(
            onTap: isUpdatingThisItem ? null : () => _showQuantityInputDialog(context, item),
            child: Container(
              width: 40,
              alignment: Alignment.center,
              child: isUpdatingThisItem
                  ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          _buildAdjustButton(
            icon: Icons.add,
            onPressed: !isUpdatingThisItem
                ? () => context.read<CartCubit>().updateQuantity(item.productId, item.caseUnitName, item.quantity + 1)
                : null,
            isAdd: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustButton({required IconData icon, VoidCallback? onPressed, bool isAdd = false}) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 16),
        color: onPressed == null ? Colors.grey : (isAdd ? AppTheme.primaryGreen : Colors.black87),
        onPressed: onPressed,
      ),
    );
  }

  void _showQuantityInputDialog(BuildContext context, CartItemModel item) {
    final TextEditingController controller = TextEditingController(text: item.quantity.toString());
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Số lượng (${item.caseUnitName})'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            validator: (value) => (value == null || int.tryParse(value) == null || int.parse(value) <= 0) ? 'Nhập số hợp lệ' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('HỦY')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<CartCubit>().updateQuantity(item.productId, item.caseUnitName, int.parse(controller.text));
                Navigator.pop(context);
              }
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    return BlocBuilder<CartSuggestionsCubit, CartSuggestionsState>(
      builder: (context, state) {
        if (state.suggestedProducts.isEmpty) return const SizedBox.shrink();

        final userRole = (context.read<AuthBloc>().state as AuthAuthenticated).user.role;
        final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text('CÓ THỂ BẠN THÍCH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textGrey, letterSpacing: 1.2)),
            ),
            SizedBox(
              height: 240,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: state.suggestedProducts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _buildSuggestionCard(context, state.suggestedProducts[index], userRole, currencyFormatter),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildSuggestionCard(BuildContext context, ProductModel product, String userRole, NumberFormat formatter) {
    return SizedBox(
      width: 150,
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: InkWell(
          onTap: () => Navigator.of(context).push(ProductDetailPage.route(product.id)),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(product.imageUrl, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(color: Colors.grey.shade100, child: const Icon(Icons.image, color: Colors.grey)))
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('${formatter.format(product.getPriceForRole(userRole))} / ${product.displayUnit}', style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, CartState state, NumberFormat formatter) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tạm tính (${state.uniqueItemCount} món)', style: const TextStyle(color: AppTheme.textGrey)),
                Text(formatter.format(state.totalPrice), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.items.isEmpty ? null : () => Navigator.of(context).push(CheckoutPage.route()),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: AppTheme.primaryGreen.withValues(alpha: 0.4),
                ),
                child: const Text('TIẾN HÀNH THANH TOÁN', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutQuart);
  }
}
