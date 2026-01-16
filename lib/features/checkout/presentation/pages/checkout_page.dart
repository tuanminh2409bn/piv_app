//lib/features/checkout/presentation/pages/checkout_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/data/models/address_model.dart';
import 'package:piv_app/data/models/cart_item_model.dart';
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';
import 'package:piv_app/features/checkout/presentation/bloc/checkout_cubit.dart';
import 'package:piv_app/features/checkout/presentation/pages/address_selection_page.dart';
import 'package:piv_app/features/orders/presentation/pages/order_success_page.dart';

// --- TIỆN ÍCH ĐỊNH DẠNG SỐ ---
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

    final maxAmount = cubit.state.totalWithDebt;
    if (amount > maxAmount) {
      amount = maxAmount;
    }
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // 1. Ẩn bàn phím khi chạm ra ngoài
      child: BlocConsumer<CheckoutCubit, CheckoutState>(
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
                backgroundColor: AppTheme.errorRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ));
          }

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
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              title: const Text('Xác nhận đơn hàng', style: TextStyle(fontWeight: FontWeight.bold)),
              elevation: 0,
              scrolledUnderElevation: 2,
              backgroundColor: Colors.white,
            ),
            body: SingleChildScrollView(
              // 2. Padding động theo bàn phím để đẩy nội dung lên
              padding: EdgeInsets.fromLTRB(16, 16, 16, 100 + MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('ĐỊA CHỈ NHẬN HÀNG', icon: Icons.location_on),
                  const SizedBox(height: 12),
                  _buildAddressSection(context).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),

                  const SizedBox(height: 24),
                  _buildSectionTitle('SẢN PHẨM', icon: Icons.shopping_bag_outlined),
                  const SizedBox(height: 12),
                  _buildOrderItems(context).animate(delay: 100.ms).fadeIn().slideX(begin: 0.1, end: 0),

                  const SizedBox(height: 24),
                  _buildSectionTitle('KHUYẾN MÃI', icon: Icons.local_offer_outlined),
                  const SizedBox(height: 12),
                  _buildVoucherSection(context).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),
                  _buildSectionTitle('THANH TOÁN', icon: Icons.payment),
                  const SizedBox(height: 12),
                  _buildOrderSummary(context, state, _currencyFormatter).animate(delay: 300.ms).fadeIn(),

                  if (state.totalWithDebt > 0) ...[
                     const SizedBox(height: 24),
                    _buildPaymentInputSection(context, state, _currencyFormatter).animate(delay: 400.ms).fadeIn(),
                  ],
                ],
              ),
            ),
            bottomNavigationBar: _buildBottomBar(context, state, _currencyFormatter),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, {required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildCardContainer({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildAddressSection(BuildContext context) {
    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, state) {
        if (state.status == CheckoutStatus.loading) {
          return _buildCardContainer(child: const Center(child: CircularProgressIndicator()));
        }

        final address = state.selectedAddress;
        
        return InkWell(
          onTap: () async {
            final selectedAddress = await Navigator.of(context).push<AddressModel?>(
              AddressSelectionPage.route(addresses: state.addresses),
            );
            if (selectedAddress != null) {
              context.read<CheckoutCubit>().selectAddress(selectedAddress);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on, color: AppTheme.primaryGreen, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: address == null
                      ? const Text('Vui lòng chọn địa chỉ nhận hàng', style: TextStyle(color: Colors.redAccent))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              address.recipientName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(address.phoneNumber, style: TextStyle(color: Colors.grey[700])),
                            const SizedBox(height: 4),
                            Text(
                              address.fullAddress,
                              style: const TextStyle(fontSize: 13, height: 1.4),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderItems(BuildContext context) {
    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, state) {
        return Column(
          children: state.checkoutItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildCardContainer(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item.imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], width: 70, height: 70),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.itemUnitName} x ${item.quantity}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(item.subtotal),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildVoucherSection(BuildContext context) {
    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, state) {
        if (state.appliedVoucher != null) {
          return _buildCardContainer(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.verified, color: Colors.green, size: 30),
              title: Text('Voucher: ${state.appliedVoucher!.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(state.appliedVoucher!.description, style: TextStyle(color: Colors.green[700])),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () => context.read<CheckoutCubit>().removeVoucher(),
              ),
            ),
          );
        }
        
        final controller = TextEditingController();
        return _buildCardContainer(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Nhập mã giảm giá',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    icon: const Icon(Icons.confirmation_number_outlined, color: Colors.grey),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    context.read<CheckoutCubit>().applyVoucher(controller.text.trim());
                    FocusScope.of(context).unfocus();
                  }
                },
                child: const Text('ÁP DỤNG', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderSummary(BuildContext context, CheckoutState state, NumberFormat currencyFormatter) {
    return _buildCardContainer(
      child: Column(
        children: [
          _buildSummaryRow('Tạm tính', currencyFormatter.format(state.subtotal)),
          const SizedBox(height: 8),
          _buildSummaryRow('Phí vận chuyển', currencyFormatter.format(state.shippingFee)),
          
          if (state.discount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _buildSummaryRow('Voucher giảm giá', '-${currencyFormatter.format(state.discount)}', valueColor: Colors.green),
            ),
            
          if (state.status == CheckoutStatus.calculatingDiscount)
             const Padding(
               padding: EdgeInsets.only(top: 8.0),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [Text("Đang tính chiết khấu...", style: TextStyle(color: Colors.orange)), SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))],
               ),
             )
          else if (state.commissionDiscount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _buildSummaryRow('Chiết khấu đại lý', '-${currencyFormatter.format(state.commissionDiscount)}', valueColor: Colors.green),
            ),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.grey[200], height: 1),
          ),
          
          _buildSummaryRow('Tiền hàng', currencyFormatter.format(state.finalTotal), isBold: true),
          
          if (state.currentDebt > 0) ...[
             const SizedBox(height: 8),
             _buildSummaryRow('Công nợ cũ', '+${currencyFormatter.format(state.currentDebt)}', valueColor: AppTheme.errorRed),
             Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Colors.grey[200], height: 1),
              ),
             _buildSummaryRow('Tổng thanh toán', currencyFormatter.format(state.totalWithDebt), isBold: true, fontSize: 18, valueColor: AppTheme.primaryGreen),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? valueColor, double fontSize = 14}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: fontSize, color: isBold ? Colors.black87 : Colors.grey[600], fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: fontSize, color: valueColor ?? (isBold ? Colors.black87 : Colors.black), fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
      ],
    );
  }

  Widget _buildPaymentInputSection(BuildContext context, CheckoutState state, NumberFormat formatter) {
     return _buildCardContainer(
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text(
             'Số tiền bạn muốn trả',
             style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold),
           ),
           const SizedBox(height: 12),
           Row(
             children: [
               Expanded(
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 16),
                   decoration: BoxDecoration(
                     color: Colors.grey[100],
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: TextField(
                     controller: _amountController,
                     keyboardType: const TextInputType.numberWithOptions(decimal: false),
                     inputFormatters: [
                       FilteringTextInputFormatter.digitsOnly,
                       CurrencyInputFormatter(),
                     ],
                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryGreen),
                     textInputAction: TextInputAction.done, // 4. Nút Done
                     decoration: InputDecoration(
                       border: InputBorder.none,
                       hintText: '0', // 3. Số mẫu là 0
                       hintStyle: const TextStyle(color: Colors.grey),
                       suffixText: 'đ',
                       suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                       suffixIcon: IconButton( // 5. Nút ẩn bàn phím
                         icon: const Icon(Icons.keyboard_hide, color: Colors.grey),
                         onPressed: () => FocusScope.of(context).unfocus(),
                       ),
                     ),
                   ),
                 ),
               ),
               const SizedBox(width: 12),
               InkWell(
                 onTap: () {
                   context.read<CheckoutCubit>().updateAmountToPay(state.totalWithDebt);
                 },
                 borderRadius: BorderRadius.circular(12),
                 child: Container(
                   padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                   decoration: BoxDecoration(
                     color: AppTheme.primaryGreen.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: const Text('TRẢ HẾT', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                 ),
               ),
             ],
           ),
         ],
       ),
     );
  }

  Widget _buildBottomBar(BuildContext context, CheckoutState state, NumberFormat currencyFormatter) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tổng cộng', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Text(
                    currencyFormatter.format(state.totalWithDebt), // Hiển thị tổng (bao gồm công nợ)
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 6,
              child: ElevatedButton(
                onPressed: (state.selectedAddress == null || state.status == CheckoutStatus.placingOrder || state.status == CheckoutStatus.calculatingDiscount)
                    ? null
                    : () => context.read<CheckoutCubit>().placeOrder(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 8,
                  shadowColor: AppTheme.primaryGreen.withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: state.status == CheckoutStatus.placingOrder
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('ĐẶT HÀNG NGAY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 500.ms, curve: Curves.easeOutQuart);
  }
}