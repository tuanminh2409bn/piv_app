// lib/features/profile/presentation/pages/debt_payment_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/orders/presentation/pages/order_success_page.dart';
import 'package:piv_app/features/profile/presentation/bloc/debt_payment_cubit.dart';

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

class DebtPaymentPage extends StatelessWidget {
  const DebtPaymentPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (context) => sl<DebtPaymentCubit>(),
        child: const DebtPaymentPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const DebtPaymentView();
  }
}

class DebtPaymentView extends StatefulWidget {
  const DebtPaymentView({super.key});

  @override
  State<DebtPaymentView> createState() => _DebtPaymentViewState();
}

class _DebtPaymentViewState extends State<DebtPaymentView> {
  final _amountController = TextEditingController();
  final _numberFormat = NumberFormat.decimalPattern('vi_VN');

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  // --- BẮT ĐẦU SỬA LỖI ---
  void _onAmountChanged() {
    final cleanText = _amountController.text.replaceAll('.', '');
    final amount = double.tryParse(cleanText) ?? 0.0;
    // Chỉ gọi update nếu giá trị trong state khác với giá trị đang nhập
    // để tránh vòng lặp không cần thiết.
    if (amount != context.read<DebtPaymentCubit>().state.amountToPay) {
      context.read<DebtPaymentCubit>().updateAmountToPay(amount);
    }
  }
  // --- KẾT THÚC SỬA LỖI ---

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- BẮT ĐẦU SỬA LỖI ---
    // Tách riêng Listener và Builder để quản lý các tác vụ phụ và việc build UI
    return MultiBlocListener(
      listeners: [
        // Listener này xử lý các tác vụ như điều hướng, hiển thị SnackBar
        BlocListener<DebtPaymentCubit, DebtPaymentState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status == DebtPaymentStatus.success && state.newOrderId != null) {
              Navigator.of(context).pushAndRemoveUntil(
                OrderSuccessPage.route(orderId: state.newOrderId!),
                    (route) => route.isFirst,
              );
            }
            if (state.status == DebtPaymentStatus.error && state.errorMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red,
                ));
              context.read<DebtPaymentCubit>().clearError();
            }
          },
        ),
        // Listener này đồng bộ state từ Cubit vào TextEditingController
        BlocListener<DebtPaymentCubit, DebtPaymentState>(
          listenWhen: (previous, current) => previous.amountToPay != current.amountToPay,
          listener: (context, state) {
            final formattedAmount = _numberFormat.format(state.amountToPay);
            if (_amountController.text != formattedAmount) {
              // Tạm thời gỡ listener để tránh vòng lặp khi cập nhật controller
              _amountController.removeListener(_onAmountChanged);
              _amountController.value = TextEditingValue(
                text: formattedAmount,
                selection: TextSelection.collapsed(offset: formattedAmount.length),
              );
              // Thêm lại listener sau khi cập nhật xong
              _amountController.addListener(_onAmountChanged);
            }
          },
        ),
      ],
      child: BlocBuilder<DebtPaymentCubit, DebtPaymentState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text('Thanh toán Công nợ')),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(context, state.currentUser.debtAmount),
                    const SizedBox(height: 24),
                    Text('Số tiền thanh toán', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                        suffixText: 'đ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            context.read<DebtPaymentCubit>().updateAmountToPay(state.currentUser.debtAmount);
                          },
                          child: const Text('TRẢ HẾT'),
                        )
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state.status == DebtPaymentStatus.loading
                            ? null
                            : () {
                          context.read<DebtPaymentCubit>().createDebtPaymentOrder();
                        },
                        child: state.status == DebtPaymentStatus.loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('TẠO LỆNH THANH TOÁN'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    // --- KẾT THÚC SỬA LỖI ---
  }

  Widget _buildSummaryCard(BuildContext context, double debtAmount) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return Card(
      elevation: 0,
      color: Colors.red.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Công nợ hiện tại', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                currencyFormat.format(debtAmount),
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}