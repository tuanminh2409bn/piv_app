// lib/features/checkout/presentation/pages/checkout_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/checkout/presentation/bloc/checkout_cubit.dart';
import 'package:piv_app/data/models/address_model.dart';
import 'package:piv_app/data/models/cart_item_model.dart';
import 'package:piv_app/features/checkout/presentation/pages/address_selection_page.dart';
import 'package:piv_app/features/orders/presentation/pages/order_success_page.dart';

class CheckoutPage extends StatelessWidget {
  final List<CartItemModel>? buyNowItems;

  const CheckoutPage({super.key, this.buyNowItems});

  static PageRoute<void> route({List<CartItemModel>? buyNowItems}) {
    return MaterialPageRoute<void>(
      builder: (_) => CheckoutPage(buyNowItems: buyNowItems),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CheckoutCubit>()..loadCheckoutData(buyNowItems: buyNowItems),
      child: const CheckoutView(),
    );
  }
}

class CheckoutView extends StatelessWidget {
  const CheckoutView({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán'), centerTitle: true),
      body: BlocConsumer<CheckoutCubit, CheckoutState>(
        listener: (context, state) {
          if (state.status == CheckoutStatus.orderSuccess) {
            Navigator.of(context).pushAndRemoveUntil(OrderSuccessPage.route(), (route) => route.isFirst);
          } else if (state.status == CheckoutStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!), backgroundColor: Theme.of(context).colorScheme.error));
          }
        },
        builder: (context, checkoutState) {
          if (checkoutState.status == CheckoutStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final isPlacingOrder = checkoutState.status == CheckoutStatus.placingOrder;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(context, 'Địa chỉ giao hàng'),
                      _buildAddressSection(context, checkoutState.selectedAddress),
                      const SizedBox(height: 24),
                      _buildSectionTitle(context, 'Sản phẩm'),
                      _buildProductSummaryList(context, checkoutState.checkoutItems, currencyFormatter),
                      const SizedBox(height: 24),
                      _buildSectionTitle(context, 'Phương thức thanh toán'),
                      _buildPaymentMethodSection(),
                    ],
                  ),
                ),
              ),
              _buildCheckoutSummary(context, checkoutState, currencyFormatter, isPlacingOrder),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductSummaryList(BuildContext context, List<CartItemModel> items, NumberFormat formatter) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(item.imageUrl, width: 50, height: 50, fit: BoxFit.cover)),
            title: Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              'SL: ${item.quantity} x ${item.caseUnitName}\n(${formatter.format(item.price)} x ${item.quantityPerPackage} ${item.itemUnitName})',
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
            trailing: Text(formatter.format(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
            isThreeLine: true,
          );
        },
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
      ),
    );
  }

  Widget _buildCheckoutSummary(BuildContext context, CheckoutState checkoutState, NumberFormat formatter, bool isPlacingOrder) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tạm tính', style: Theme.of(context).textTheme.bodyLarge), Text(formatter.format(checkoutState.subtotal))]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Phí vận chuyển', style: Theme.of(context).textTheme.bodyLarge), Text(formatter.format(checkoutState.shippingFee))]),
          const Divider(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Tổng cộng', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text(formatter.format(checkoutState.total), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: (checkoutState.selectedAddress == null || checkoutState.checkoutItems.isEmpty || isPlacingOrder) ? null : () {
                context.read<CheckoutCubit>().placeOrder();
              },
              child: isPlacingOrder ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Text('ĐẶT HÀNG'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAddressSection(BuildContext context, AddressModel? selectedAddress) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          final checkoutCubit = context.read<CheckoutCubit>();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => BlocProvider.value(value: checkoutCubit, child: const AddressSelectionPage())),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: selectedAddress == null
                    ? const Text('Vui lòng chọn hoặc thêm địa chỉ.')
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${selectedAddress.recipientName} | ${selectedAddress.phoneNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(selectedAddress.fullAddress, style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(Icons.account_balance_wallet_outlined, color: Colors.blue.shade700),
        title: const Text('Thanh toán khi nhận hàng (COD)'),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }
}