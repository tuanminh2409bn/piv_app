import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/address_model.dart';
import 'package:piv_app/data/models/cart_item_model.dart';
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';
import 'package:piv_app/features/checkout/presentation/bloc/checkout_cubit.dart';
import 'package:piv_app/features/checkout/presentation/pages/address_selection_page.dart';
import 'package:piv_app/features/orders/presentation/pages/order_success_page.dart';

class CheckoutPage extends StatelessWidget {
  final List<CartItemModel>? buyNowItems;

  const CheckoutPage({super.key, this.buyNowItems});

  static PageRoute<void> route({List<CartItemModel>? buyNowItems}) {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (context) => sl<CheckoutCubit>()..loadCheckoutData(buyNowItems: buyNowItems),
        child: CheckoutPage(buyNowItems: buyNowItems),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const CheckoutView();
  }
}

class CheckoutView extends StatelessWidget {
  const CheckoutView({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<CheckoutCubit>().state;
      if (state.status == CheckoutStatus.error && state.errorMessage != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận đơn hàng')),
      body: BlocListener<CheckoutCubit, CheckoutState>(
        listener: (context, state) {
          if (state.status == CheckoutStatus.orderSuccess && state.newOrderId != null) {
            Navigator.of(context).pushAndRemoveUntil(
                OrderSuccessPage.route(orderId: state.newOrderId!),
                    (route) => route.isFirst);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAddressSection(context),
              const Divider(thickness: 8, height: 32),
              _buildOrderItems(context),
              const Divider(thickness: 8, height: 32),
              _buildVoucherSection(context),
              const Divider(thickness: 8, height: 32),
              _buildOrderSummary(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildPlaceOrderButton(context),
    );
  }

  Widget _buildAddressSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Địa chỉ giao hàng', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          BlocBuilder<CheckoutCubit, CheckoutState>(
            builder: (context, state) {
              if (state.status == CheckoutStatus.loading) {
                return const Text('Đang tải địa chỉ...');
              }
              if (state.selectedAddress == null) {
                return Center(
                  child: OutlinedButton(
                    onPressed: () async {
                      final selectedAddress = await Navigator.of(context).push<AddressModel?>(
                        AddressSelectionPage.route(addresses: state.addresses),
                      );
                      if (selectedAddress != null) {
                        context.read<CheckoutCubit>().selectAddress(selectedAddress);
                      }
                    },
                    child: const Text('Chọn hoặc thêm địa chỉ'),
                  ),
                );
              }
              return InkWell(
                onTap: () async {
                  final selectedAddress = await Navigator.of(context).push<AddressModel?>(
                    AddressSelectionPage.route(addresses: state.addresses),
                  );
                  if (selectedAddress != null) {
                    context.read<CheckoutCubit>().selectAddress(selectedAddress);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${state.selectedAddress!.recipientName} | ${state.selectedAddress!.phoneNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(state.selectedAddress!.fullAddress),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sản phẩm', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          BlocBuilder<CheckoutCubit, CheckoutState>(
            builder: (context, state) {
              return ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: state.checkoutItems.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (context, index) {
                  final item = state.checkoutItems[index];
                  return Row(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item.imageUrl, width: 60, height: 60, fit: BoxFit.cover)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis),
                            Text('SL: ${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Text(NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(item.subtotal)),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Phương thức thanh toán', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          BlocBuilder<CheckoutCubit, CheckoutState>(
            builder: (context, state) {
              return Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('Thanh toán khi nhận hàng (COD)'),
                    value: 'COD',
                    groupValue: state.paymentMethod,
                    onChanged: (value) {
                      if (value != null) {
                        context.read<CheckoutCubit>().selectPaymentMethod(value);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Thanh toán Online (VNPAY, MoMo,...)'),
                    value: 'ONLINE',
                    groupValue: state.paymentMethod,
                    onChanged: (value) {
                      if (value != null) {
                        context.read<CheckoutCubit>().selectPaymentMethod(value);
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherSection(BuildContext context) {
    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, state) {
        if (state.appliedVoucher != null) {
          return _buildAppliedVoucherCard(context, state.appliedVoucher!);
        } else {
          return _buildVoucherInput(context);
        }
      },
    );
  }

  Widget _buildVoucherInput(BuildContext context) {
    final controller = TextEditingController();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Mã giảm giá (tùy chọn)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<CheckoutCubit>().applyVoucher(controller.text.trim());
                FocusScope.of(context).unfocus();
              }
            },
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppliedVoucherCard(BuildContext context, VoucherModel voucher) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        color: Colors.green.shade50,
        elevation: 0,
        shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.green), borderRadius: BorderRadius.circular(8)),
        child: ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: Text('Đã áp dụng mã: ${voucher.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(voucher.description),
          trailing: IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            tooltip: 'Xóa mã',
            onPressed: () => context.read<CheckoutCubit>().removeVoucher(),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tóm tắt đơn hàng', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          BlocBuilder<CheckoutCubit, CheckoutState>(
            builder: (context, state) {
              return Column(
                children: [
                  _buildSummaryRow('Tạm tính:', currencyFormatter.format(state.subtotal)),
                  _buildSummaryRow('Phí vận chuyển:', currencyFormatter.format(state.shippingFee)),
                  if (state.discount > 0)
                    _buildSummaryRow(
                      'Giảm giá voucher:',
                      '- ${currencyFormatter.format(state.discount)}',
                      color: Colors.green.shade700,
                    ),

                  if (state.status == CheckoutStatus.calculatingDiscount)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Chiết khấu đại lý:", style: TextStyle(fontSize: 16)),
                          SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        ],
                      ),
                    )
                  else if (state.commissionDiscount > 0)
                    _buildSummaryRow(
                      'Chiết khấu đại lý:',
                      '- ${currencyFormatter.format(state.commissionDiscount)}',
                      color: Colors.green.shade700,
                    ),

                  const Divider(),
                  _buildSummaryRow(
                    'Tổng cộng:',
                    currencyFormatter.format(state.finalTotal),
                    isTotal: true,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, {bool isTotal = false, Color? color}) {
    final style = TextStyle(
      fontSize: isTotal ? 18 : 16,
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: BlocBuilder<CheckoutCubit, CheckoutState>(
        builder: (context, state) {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (state.selectedAddress == null || state.status == CheckoutStatus.placingOrder || state.status == CheckoutStatus.calculatingDiscount)
                  ? null
                  : () => context.read<CheckoutCubit>().placeOrder(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: state.status == CheckoutStatus.placingOrder
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Text('ĐẶT HÀNG'),
            ),
          );
        },
      ),
    );
  }
}