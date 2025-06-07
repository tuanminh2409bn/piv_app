import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:piv_app/data/models/cart_item_model.dart';
// Import CheckoutPage
import 'package:piv_app/features/checkout/presentation/pages/checkout_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const CartPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const CartView();
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
      body: BlocConsumer<CartCubit, CartState>(
        listener: (context, state) {
          if (state.status == CartStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ));
          }
        },
        builder: (context, state) {
          if (state.status == CartStatus.loading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Giỏ hàng của bạn đang trống', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Hãy thêm sản phẩm để mua sắm nhé!', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Tiếp tục mua sắm')
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: state.items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return _buildCartItemCard(context, item, currencyFormatter);
                  },
                ),
              ),
              _buildSummarySection(context, state, currencyFormatter),
            ],
          );
        },
      ),
    );
  }
}

// ... (_buildCartItemCard và _buildQuantityAdjuster không đổi) ...
Widget _buildCartItemCard(BuildContext context, CartItemModel item, NumberFormat formatter) {
  return Card(
    elevation: 2,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.imageUrl,
              width: 80, height: 80, fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 80, height: 80, color: Colors.grey.shade200,
                child: const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(formatter.format(item.price), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildQuantityAdjuster(context, item),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 24),
              onPressed: () {
                context.read<CartCubit>().removeProduct(item.productId);
              },
            ),
          )
        ],
      ),
    ),
  );
}

Widget _buildQuantityAdjuster(BuildContext context, CartItemModel item) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 30,
        height: 30,
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.remove_circle_outline, size: 22),
          color: Colors.grey.shade600,
          onPressed: item.quantity > 1
              ? () => context.read<CartCubit>().updateQuantity(item.productId, item.quantity - 1)
              : null,
        ),
      ),
      GestureDetector(
        onTap: () {
          _showQuantityInputDialog(context, item);
        },
        child: Container(
          width: 50,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 1.0),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
              item.quantity.toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
          ),
        ),
      ),
      SizedBox(
        width: 30,
        height: 30,
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.add_circle, size: 22),
          color: Theme.of(context).colorScheme.primary,
          onPressed: () => context.read<CartCubit>().updateQuantity(item.productId, item.quantity + 1),
        ),
      ),
    ],
  );
}

void _showQuantityInputDialog(BuildContext context, CartItemModel item) {
  final TextEditingController controller = TextEditingController(text: item.quantity.toString());
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Nhập số lượng'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: 'Số lượng',
            ),
            textAlign: TextAlign.center,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập số lượng';
              }
              final quantity = int.tryParse(value);
              if (quantity == null || quantity <= 0) {
                return 'Số lượng phải lớn hơn 0';
              }
              return null;
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('HỦY'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
          ElevatedButton(
            child: const Text('XÁC NHẬN'),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newQuantity = int.parse(controller.text);
                context.read<CartCubit>().updateQuantity(item.productId, newQuantity);
                Navigator.of(dialogContext).pop();
              }
            },
          ),
        ],
      );
    },
  );
}


// CẬP NHẬT PHẦN NÀY
Widget _buildSummarySection(BuildContext context, CartState state, NumberFormat formatter) {
  return Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
      border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tổng cộng (${state.totalItems} sản phẩm):', style: Theme.of(context).textTheme.titleMedium),
            Text(formatter.format(state.totalPrice), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.items.isEmpty ? null : () {
              // Điều hướng đến trang thanh toán
              Navigator.of(context).push(CheckoutPage.route());
            },
            child: const Text('Tiến hành Thanh toán'),
          ),
        )
      ],
    ),
  );
}
