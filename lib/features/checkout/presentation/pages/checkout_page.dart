//lib/features/checkout/presentation/pages/checkout_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/data/models/address_model.dart';
import 'package:piv_app/data/models/cart_item_model.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/checkout/presentation/bloc/checkout_cubit.dart';
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';
import 'address_selection_page.dart';
import 'package:piv_app/features/orders/presentation/pages/order_success_page.dart';

import 'package:piv_app/core/di/injection_container.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItemModel>? buyNowItems;
  final UserModel? onBehalfOfAgent;

  const CheckoutPage({super.key, this.buyNowItems, this.onBehalfOfAgent});

  static Route<void> route({List<CartItemModel>? buyNowItems, UserModel? onBehalfOfAgent}) {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (context) => sl<CheckoutCubit>(),
        child: CheckoutPage(buyNowItems: buyNowItems, onBehalfOfAgent: onBehalfOfAgent),
      ),
    );
  }

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onBehalfOfAgent != null) {
        context.read<CheckoutCubit>().loadCheckoutDataForAgent(widget.onBehalfOfAgent!);
      } else {
        context.read<CheckoutCubit>().loadCheckoutData(buyNowItems: widget.buyNowItems);
      }
    });
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return BlocConsumer<CheckoutCubit, CheckoutState>(
      listener: (context, state) {
        if (state.status == CheckoutStatus.orderSuccess && state.newOrderId != null) {
          Navigator.of(context).pushReplacement(OrderSuccessPage.route(orderId: state.newOrderId!));
        }
        if (state.status == CheckoutStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!), backgroundColor: AppTheme.errorRed),
          );
        }
        
        // Tự động điền số tiền cần thanh toán
        final totalStr = currencyFormatter.format(state.amountToPay).replaceAll(RegExp(r'[^0-9]'), '');
        if (amountController.text.replaceAll('.', '') != totalStr) {
           amountController.text = NumberFormat.decimalPattern('vi_VN').format(state.amountToPay);
        }
      },
      builder: (context, state) {
        if (state.status == CheckoutStatus.loading && state.checkoutItems.isEmpty) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          appBar: AppBar(
            title: Text(widget.onBehalfOfAgent != null ? 'Đặt hàng hộ' : 'Xác nhận đơn hàng'),
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.textDark,
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Địa chỉ nhận hàng'),
                      _buildAddressSection(context, state),
                      const SizedBox(height: 20),
                      
                      _buildSectionTitle('Sản phẩm đã chọn'),
                      _buildOrderItems(state),
                      const SizedBox(height: 20),
                      
                      _buildSectionTitle('Khuyến mãi'),
                      _buildVoucherSection(context, state),
                      const SizedBox(height: 20),
                      
                      _buildSectionTitle('Phương thức thanh toán'),
                      _buildPaymentMethodSection(context, state),
                      const SizedBox(height: 20),
                      
                      _buildSectionTitle('Chi tiết thanh toán'),
                      _buildOrderSummary(context, state, currencyFormatter),
                      const SizedBox(height: 20),
                      
                      if (widget.onBehalfOfAgent == null) ...[
                        _buildSectionTitle('Số tiền thanh toán ngay'),
                        _buildPaymentInputSection(context, state, currencyFormatter),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
              ),
              _buildBottomBar(context, state, currencyFormatter),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildAddressSection(BuildContext context, CheckoutState state) {
    return _buildCardContainer(
      child: InkWell(
        onTap: () async {
          final addresses = state.addresses;
          final result = await Navigator.of(context).push<AddressModel?>(
            AddressSelectionPage.route(addresses: addresses, selectedAddress: state.selectedAddress),
          );
          if (result != null) {
            context.read<CheckoutCubit>().selectAddress(result);
          }
        },
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, color: AppTheme.primaryGreen, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: state.selectedAddress != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.selectedAddress!.recipientName} | ${state.selectedAddress!.phoneNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.selectedAddress!.fullAddress,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    )
                  : const Text('Vui lòng chọn địa chỉ nhận hàng', style: TextStyle(color: Colors.red)),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems(CheckoutState state) {
    return _buildCardContainer(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: state.checkoutItems.length,
        separatorBuilder: (_, __) => Divider(color: Colors.grey[100], height: 24),
        itemBuilder: (context, index) {
          final item = state.checkoutItems[index];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(item.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: item.quantityPerPackage > 1 
                                ? AppTheme.primaryGreen.withValues(alpha: 0.1) 
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: item.quantityPerPackage > 1 
                                  ? AppTheme.primaryGreen.withValues(alpha: 0.3) 
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            item.quantityPerPackage > 1 ? 'THÙNG' : 'LẺ',
                            style: TextStyle(
                              color: item.quantityPerPackage > 1 ? AppTheme.primaryGreen : Colors.grey[700],
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.quantityPerPackage > 1 
                                ? '${item.quantity} ${item.caseUnitName} (${item.quantityPerPackage} ${item.itemUnitName}/thùng)'
                                : '${item.quantity} ${item.itemUnitName} lẻ',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVoucherSection(BuildContext context, CheckoutState state) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    if (state.appliedVoucher != null) {
      return _buildCardContainer(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.confirmation_number, color: Colors.green),
          ),
          title: Text('Voucher: ${state.appliedVoucher!.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Đã giảm ${currencyFormatter.format(state.discount)}', style: const TextStyle(color: Colors.green)),
          trailing: TextButton(
            child: const Text('GỠ BỎ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onPressed: () => context.read<CheckoutCubit>().removeVoucher(),
          ),
        ),
      );
    }
    
    return _buildCardContainer(
      child: InkWell(
        onTap: () => _showVoucherSelection(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.sell_outlined, color: Colors.grey),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Chọn voucher giảm giá', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.withValues(alpha: 0.5), size: 14),
            ],
          ),
        ),
      ),
    );
  }

  void _showVoucherSelection(BuildContext context) {
    final checkoutCubit = context.read<CheckoutCubit>();
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppTheme.backgroundLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text('Chọn Voucher', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<CheckoutCubit, CheckoutState>(
                bloc: checkoutCubit,
                builder: (context, state) {
                  if (state.availableVouchers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('Bạn chưa có voucher nào khả dụng', style: TextStyle(color: AppTheme.textGrey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: state.availableVouchers.length,
                    itemBuilder: (context, index) {
                      final voucher = state.availableVouchers[index];
                      final isApplicable = state.subtotal >= voucher.minOrderValue;
                      
                      String discountDesc = '';
                      if (voucher.discountType == DiscountType.percentage) {
                        discountDesc = 'Giảm ${voucher.discountValue.toInt()}%';
                        if (voucher.maxDiscountAmount != null) {
                          discountDesc += ' (Tối đa ${currencyFormatter.format(voucher.maxDiscountAmount)})';
                        }
                      } else if (voucher.discountType == DiscountType.fixedAmount) {
                        discountDesc = 'Giảm ${currencyFormatter.format(voucher.discountValue)}';
                      } else if (voucher.discountType == DiscountType.buyXGetY) {
                        discountDesc = 'Mua ${voucher.buyQuantity} tặng ${voucher.getQuantity} (áp dụng cho hàng thùng)';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isApplicable ? Colors.transparent : Colors.grey.shade200,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: InkWell(
                          onTap: isApplicable ? () {
                            checkoutCubit.selectVoucher(voucher);
                            Navigator.pop(context);
                          } : null,
                          borderRadius: BorderRadius.circular(16),
                          child: Opacity(
                            opacity: isApplicable ? 1.0 : 0.6,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isApplicable ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.confirmation_number, 
                                      color: isApplicable ? AppTheme.primaryGreen : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          voucher.id,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          discountDesc,
                                          style: TextStyle(color: isApplicable ? Colors.orange.shade700 : AppTheme.textGrey, fontWeight: FontWeight.w500, fontSize: 13),
                                        ),
                                        if (!isApplicable)
                                          Text(
                                            'Chưa đủ ĐK: Đơn từ ${currencyFormatter.format(voucher.minOrderValue)}',
                                            style: const TextStyle(color: Colors.red, fontSize: 11),
                                          ),
                                        Text(
                                          'HSD: ${DateFormat('dd/MM/yyyy').format(voucher.expiresAt.toDate())}',
                                          style: const TextStyle(color: AppTheme.textGrey, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isApplicable)
                                    const Icon(Icons.chevron_right, color: AppTheme.primaryGreen),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection(BuildContext context, CheckoutState state) {
    return _buildCardContainer(
      child: Column(
        children: [
          _buildPaymentOption(
            context,
            'COD',
            'Thanh toán khi nhận hàng',
            Icons.money,
            state.paymentMethod == 'COD',
          ),
          const Divider(height: 1),
          _buildPaymentOption(
            context,
            'bank_transfer',
            'Chuyển khoản ngân hàng',
            Icons.account_balance,
            state.paymentMethod == 'bank_transfer',
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(BuildContext context, String value, String label, IconData icon, bool isSelected) {
    return RadioListTile<String>(
      value: value,
      groupValue: isSelected ? value : null,
      onChanged: (val) {
        if (val != null) context.read<CheckoutCubit>().selectPaymentMethod(val);
      },
      title: Text(label, style: const TextStyle(fontSize: 14)),
      secondary: Icon(icon, color: isSelected ? AppTheme.primaryGreen : Colors.grey),
      activeColor: AppTheme.primaryGreen,
      contentPadding: EdgeInsets.zero,
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
          
          if (state.currentDebt != 0) ...[
             const SizedBox(height: 8),
             _buildSummaryRow(
               state.currentDebt > 0 ? 'Công nợ cũ' : 'Dư nợ hiện tại', 
               '${state.currentDebt > 0 ? '+' : ''}${currencyFormatter.format(state.currentDebt)}', 
               valueColor: state.currentDebt > 0 ? AppTheme.errorRed : AppTheme.primaryGreen
             ),
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
           const Text('Nhập số tiền bạn muốn trả ngay:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
           const SizedBox(height: 12),
           TextField(
             controller: amountController,
             keyboardType: TextInputType.number,
             style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
             decoration: InputDecoration(
               suffixText: 'VNĐ',
               suffixStyle: const TextStyle(fontSize: 16, color: Colors.grey),
               border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             ),
             inputFormatters: [
               FilteringTextInputFormatter.digitsOnly,
               _CurrencyInputFormatter(),
             ],
             onChanged: (value) {
               final numericValue = double.tryParse(value.replaceAll('.', '')) ?? 0;
               context.read<CheckoutCubit>().updateAmountToPay(numericValue);
             },
           ),
           const SizedBox(height: 8),
           Text(
             'Còn lại: ${formatter.format((state.totalWithDebt - state.amountToPay).clamp(0, double.infinity))} sẽ tính vào công nợ.',
             style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
           ),
         ],
       ),
     );
  }

  Widget _buildBottomBar(BuildContext context, CheckoutState state, NumberFormat currencyFormatter) {
    final bool canPlaceOrder = state.selectedAddress != null &&
        (state.checkoutItems.isNotEmpty || state.currentDebt != 0) &&
        state.status != CheckoutStatus.placingOrder;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tổng thanh toán', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                  Text(
                    currencyFormatter.format(state.totalWithDebt),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              height: 50,
              width: 160,
              child: ElevatedButton(
                onPressed: canPlaceOrder 
                    ? () {
                        if (widget.onBehalfOfAgent != null) {
                          context.read<CheckoutCubit>().placeOrderOnBehalfOf();
                        } else {
                          context.read<CheckoutCubit>().placeOrder();
                        }
                      } 
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: state.status == CheckoutStatus.placingOrder
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('ĐẶT HÀNG', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    final intValue = int.parse(newValue.text.replaceAll(RegExp(r'[^0-9]'), ''));
    final newText = NumberFormat.decimalPattern('vi_VN').format(intValue);
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
