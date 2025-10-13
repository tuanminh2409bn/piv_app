// lib/features/cart/presentation/pages/cart_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
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
    return MaterialPageRoute<void>(
      builder: (_) => const CartPage(),
    );
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
      appBar: AppBar(
        title: const Text('Giỏ hàng của bạn'),
        centerTitle: true,
      ),
      body: BlocListener<CartCubit, CartState>(
        listener: (context, state) {
          if (state.status == CartStatus.itemRemovedSuccess) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(
                content: Text('Đã xoá sản phẩm khỏi giỏ hàng.'),
                backgroundColor: Colors.redAccent,
              ));
          } else if (state.status == CartStatus.itemAddedSuccess) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(
                content: Text('Đã thêm sản phẩm vào giỏ hàng!'),
                backgroundColor: Colors.green,
              ));
          } else if (state.status == CartStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ));
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
                context.read<CartSuggestionsCubit>().fetchSuggestions(
                  lastItem.categoryId,
                  currentProductId: lastItem.productId,
                );
              }
            });

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      children: [
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.items.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final item = state.items[index];
                            return _buildCartItemCard(context, item, currencyFormatter);
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildSuggestionsSection(),
                      ],
                    ),
                  ),
                ),
                _buildSummarySection(context, state, currencyFormatter),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(24.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey), const SizedBox(height: 16), Text('Giỏ hàng của bạn đang trống', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), const Text('Hãy thêm sản phẩm để mua sắm nhé!', textAlign: TextAlign.center), const SizedBox(height: 24), ElevatedButton(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), child: const Text('Tiếp tục mua sắm'))])));
  }

  // SỬA LỖI OVERFLOW Ở ĐÂY
  Widget _buildCartItemCard(BuildContext context, CartItemModel item, NumberFormat formatter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 5, offset: const Offset(0, 3))]),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => Navigator.of(context).push(ProductDetailPage.route(item.productId)),
              child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item.imageUrl, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(width:80, height:80, color: Colors.grey.shade200, child: const Icon(Icons.image)))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(item.caseUnitName, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text(formatter.format(item.subtotal), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), visualDensity: VisualDensity.compact, icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 22), onPressed: () => context.read<CartCubit>().removeProduct(item.productId, item.caseUnitName)),
                const SizedBox(height: 15),
                _buildQuantityAdjuster(context, item),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    return BlocBuilder<CartSuggestionsCubit, CartSuggestionsState>(
      builder: (context, state) {
        if (state.status == SuggestionsStatus.loading) {
          return const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()));
        }
        if (state.suggestedProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        final userRole = (context.read<AuthBloc>().state as AuthAuthenticated).user.role;
        final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Có thể bạn cũng thích', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: state.suggestedProducts.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final product = state.suggestedProducts[index];
                  return _buildSuggestionCard(context, product, userRole, currencyFormatter);
                },
              ),
            ),
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
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(ProductDetailPage.route(product.id)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Image.network(product.imageUrl, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image)))),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('${formatter.format(product.getPriceForRole(userRole))} / ${product.displayUnit}', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityAdjuster(BuildContext context, CartItemModel item) { final cartStatus = context.watch<CartCubit>().state.status; final bool isUpdatingThisItem = cartStatus == CartStatus.itemUpdating; return Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: 30, height: 30, child: IconButton(padding: EdgeInsets.zero, icon: const Icon(Icons.remove_circle_outline, size: 22), color: Colors.grey.shade600, onPressed: (item.quantity > 1 && !isUpdatingThisItem) ? () => context.read<CartCubit>().updateQuantity(item.productId, item.caseUnitName, item.quantity - 1) : null)), GestureDetector(onTap: isUpdatingThisItem ? null : () => _showQuantityInputDialog(context, item), child: Container(width: 50, alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 4), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)), child: isUpdatingThisItem ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(item.quantity.toString(), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)))), SizedBox(width: 30, height: 30, child: IconButton(padding: EdgeInsets.zero, icon: const Icon(Icons.add_circle, size: 22), color: Theme.of(context).colorScheme.primary, onPressed: !isUpdatingThisItem ? () => context.read<CartCubit>().updateQuantity(item.productId, item.caseUnitName, item.quantity + 1) : null))]); }
  void _showQuantityInputDialog(BuildContext context, CartItemModel item) { final TextEditingController controller = TextEditingController(text: item.quantity.toString()); final formKey = GlobalKey<FormState>(); showDialog(context: context, builder: (dialogContext) { return AlertDialog(title: Text('Nhập số lượng (${item.caseUnitName})'), content: Form(key: formKey, child: TextFormField(controller: controller, autofocus: true, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(hintText: 'Số lượng'), textAlign: TextAlign.center, validator: (value) { if (value == null || value.isEmpty) return 'Vui lòng nhập số lượng'; final quantity = int.tryParse(value); if (quantity == null || quantity <= 0) return 'Số lượng phải lớn hơn 0'; return null; })), actions: <Widget>[TextButton(child: const Text('HỦY'), onPressed: () => Navigator.of(dialogContext).pop()), ElevatedButton(child: const Text('XÁC NHẬN'), onPressed: () { if (formKey.currentState!.validate()) { final newQuantity = int.parse(controller.text); context.read<CartCubit>().updateQuantity(item.productId, item.caseUnitName, newQuantity); Navigator.of(dialogContext).pop(); } })]); }); }

  // SỬA LỖI OVERFLOW Ở ĐÂY
  Widget _buildSummarySection(BuildContext context, CartState state, NumberFormat formatter) {
    return Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -5))],
            border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1.5))
        ),
        child: Column(
            children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded( // << Bọc widget Text trong Expanded
                      child: Text(
                        'Tổng cộng (${state.uniqueItemCount} loại sản phẩm):',
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                        formatter.format(state.totalPrice),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)
                    )
                  ]
              ),
              const SizedBox(height: 16),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: state.items.isEmpty ? null : () => Navigator.of(context).push(CheckoutPage.route()),
                      child: const Text('Tiến hành Thanh toán')
                  )
              )
            ]
        )
    );
  }
}