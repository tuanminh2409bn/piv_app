import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/orders/presentation/pages/order_success_page.dart';
import 'package:piv_app/features/profile/presentation/bloc/debt_payment_cubit.dart';

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
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      final amount = double.tryParse(_amountController.text);
      if (amount != null) {
        context.read<DebtPaymentCubit>().updateAmountToPay(amount);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DebtPaymentCubit, DebtPaymentState>(
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
        }

        final formattedAmount = state.amountToPay.toStringAsFixed(0);
        if (_amountController.text != formattedAmount) {
          _amountController.text = formattedAmount;
          _amountController.selection = TextSelection.fromPosition(TextPosition(offset: _amountController.text.length));
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Thanh toán Công nợ')),
          // --- BỌC BODY BẰNG SAFEA ---
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                        onPressed: () => context.read<DebtPaymentCubit>().updateAmountToPay(state.currentUser.debtAmount),
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
                          : () => context.read<DebtPaymentCubit>().createDebtPaymentOrder(),
                      child: state.status == DebtPaymentStatus.loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('TẠO LỆNH THANH TOÁN'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // --------------------------
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, double debtAmount) {
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
            Text(
              _currencyFormat.format(debtAmount),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}