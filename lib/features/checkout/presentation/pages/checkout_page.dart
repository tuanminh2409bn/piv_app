//lib/features/checkout/presentation/pages/checkout_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/address_model.dart';
import 'package:piv_app/data/models/cart_item_model.dart';
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';
import 'package:piv_app/features/checkout/presentation/bloc/checkout_cubit.dart';
import 'package:piv_app/features/checkout/presentation/pages/address_selection_page.dart';
import 'package:piv_app/features/orders/presentation/pages/order_success_page.dart';

// --- TIỆN ÍCH ĐỊNH DẠNG SỐ (TÁI SỬ DỤNG) ---
class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('vi_VN');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final number = int.parse(cleanText);
    final formattedText = _formatter.format(number);

    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
// ------------------------------------------

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

class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  final TextEditingController _amountController = TextEditingController();
  final NumberFormat _currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final NumberFormat _numberFormatter = NumberFormat.decimalPattern('vi_VN');

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    final cubit = context.read<CheckoutCubit>();
    final cleanText = _amountController.text.replaceAll('.', '');
    double amount = double.tryParse(cleanText) ?? 0.0;

    // --- BẮT ĐẦU SỬA LỖI: Giới hạn giá trị nhập ---
    final maxAmount = cubit.state.totalWithDebt;
    if (amount > maxAmount) {
      amount = maxAmount;
    }
    // ------------------------------------------

    cubit.updateAmountToPay(amount);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CheckoutCubit, CheckoutState>(
      listener: (context, state) {
        if (state.status == CheckoutStatus.orderSuccess && state.newOrderId != null) {
          Navigator.of(context).pushAndRemoveUntil(
            OrderSuccessPage.route(orderId: state.newOrderId!),
                (route) => route.isFirst,
          );
        }

        if (state.status == CheckoutStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ));
        }

        // Cập nhật text field khi state thay đổi từ cubit
        final formattedAmount = _numberFormatter.format(state.amountToPay);
        if (_amountController.text != formattedAmount) {
          _amountController.value = TextEditingValue(
            text: formattedAmount,
            selection: TextSelection.collapsed(offset: formattedAmount.length),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Xác nhận đơn hàng')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAddressSection(context),
                const Divider(thickness: 8, height: 32),
                _buildOrderItems(context),
                const Divider(thickness: 8, height: 32),
                _buildVoucherSection(context),
                const Divider(thickness: 8, height: 32),
                _buildOrderSummary(context, state, _currencyFormatter),
                const Divider(thickness: 8, height: 32),
                _buildPaymentInputSection(context, state, _currencyFormatter),
              ],
            ),
          ),
          bottomNavigationBar: _buildPlaceOrderButton(context),
        );
      },
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

  Widget _buildPaymentInputSection(BuildContext context, CheckoutState state, NumberFormat formatter) {
    // Chỉ hiển thị khi có công nợ hoặc có đơn hàng (để có thể trả trước)
    if (state.totalWithDebt <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thanh toán', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CurrencyInputFormatter(), // Áp dụng formatter
            ],
            decoration: InputDecoration(
              labelText: 'Số tiền thanh toán',
              suffixText: 'đ',
              hintText: 'Nhập số tiền bạn muốn trả',
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập số tiền';
              }
              final cleanValue = value.replaceAll('.', '');
              final amount = double.tryParse(cleanValue) ?? -1;
              if (amount > state.totalWithDebt) {
                return 'Không được lớn hơn tổng thanh toán';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  context.read<CheckoutCubit>().updateAmountToPay(state.totalWithDebt);
                },
                child: const Text('TRẢ HẾT'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context, CheckoutState state, NumberFormat currencyFormatter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tóm tắt đơn hàng', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
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

          // --- THAY ĐỔI: Thêm dòng công nợ và sửa tổng cộng ---
          const Divider(),
          _buildSummaryRow(
            'Tiền hàng:',
            currencyFormatter.format(state.finalTotal),
            isTotal: true,
          ),
          if (state.currentDebt > 0)
            _buildSummaryRow(
              'Công nợ hiện tại:',
              '+ ${currencyFormatter.format(state.currentDebt)}',
              color: Colors.red.shade700,
            ),
          const Divider(),
          _buildSummaryRow(
            'Tổng thanh toán:',
            currencyFormatter.format(state.totalWithDebt),
            isTotal: true,
          ),
          // ----------------------------------------------------
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