// lib/features/profile/presentation/pages/debt_payment_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/common/widgets/responsive_wrapper.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/core/theme/nature_background_painter.dart';
import 'package:piv_app/core/utils/responsive.dart';
import 'package:piv_app/features/orders/presentation/pages/order_success_page.dart';
import 'package:piv_app/features/profile/presentation/bloc/debt_payment_cubit.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('vi_VN');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    final cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty)
      return const TextEditingValue(
          text: '', selection: TextSelection.collapsed(offset: 0));
    final number = int.parse(cleanText);
    final formattedText = _formatter.format(number);
    return newValue.copyWith(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length));
  }
}

class DebtPaymentPage extends StatelessWidget {
  const DebtPaymentPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(
        builder: (_) => BlocProvider(
            create: (context) => sl<DebtPaymentCubit>(),
            child: const DebtPaymentPage()));
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

  void _onAmountChanged() {
    final cleanText = _amountController.text.replaceAll('.', '');
    final amount = double.tryParse(cleanText) ?? 0.0;
    if (amount != context.read<DebtPaymentCubit>().state.amountToPay) {
      context.read<DebtPaymentCubit>().updateAmountToPay(amount);
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DebtPaymentCubit, DebtPaymentState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status == DebtPaymentStatus.success &&
                state.newOrderId != null) {
              Navigator.of(context).pushAndRemoveUntil(
                  OrderSuccessPage.route(orderId: state.newOrderId!),
                  (route) => route.isFirst);
            }
            if (state.status == DebtPaymentStatus.error &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: AppTheme.errorRed));
              context.read<DebtPaymentCubit>().clearError();
            }
          },
        ),
        BlocListener<DebtPaymentCubit, DebtPaymentState>(
          listenWhen: (previous, current) =>
              previous.amountToPay != current.amountToPay,
          listener: (context, state) {
            final formattedAmount = _numberFormat.format(state.amountToPay);
            if (_amountController.text != formattedAmount) {
              _amountController.removeListener(_onAmountChanged);
              _amountController.value = TextEditingValue(
                  text: formattedAmount,
                  selection:
                      TextSelection.collapsed(offset: formattedAmount.length));
              _amountController.addListener(_onAmountChanged);
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: NatureBackgroundPainter(
                  color1: AppTheme.primaryGreen.withValues(alpha: 0.05),
                  color2: AppTheme.secondaryGreen.withValues(alpha: 0.03),
                  accent: AppTheme.accentGold.withValues(alpha: 0.1),
                ),
              ),
            ),
            BlocBuilder<DebtPaymentCubit, DebtPaymentState>(
              builder: (context, state) {
                final double screenWidth = MediaQuery.of(context).size.width;
                final bool isDesktop = Responsive.isDesktop(context);
                final double horizontalPadding = (isDesktop && screenWidth > 900) 
                    ? (screenWidth - 900) / 2 
                    : 0;

                return RefreshIndicator.adaptive(
                  onRefresh: () =>
                      context.read<DebtPaymentCubit>().refreshDebt(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 120.0,
                        pinned: true,
                        backgroundColor: AppTheme.primaryGreen,
                        automaticallyImplyLeading: false,
                        leadingWidth: horizontalPadding + 56,
                        leading: Padding(
                          padding: EdgeInsets.only(left: horizontalPadding),
                          child: const BackButton(color: Colors.white),
                        ),
                        flexibleSpace: FlexibleSpaceBar(
                          centerTitle: true,
                          titlePadding: EdgeInsets.only(
                            left: horizontalPadding + 16,
                            right: horizontalPadding + 16,
                            bottom: 16,
                          ),
                          title: const Text('Thanh toán Công nợ',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                          background: Stack(
                            children: [
                              Container(
                                  decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                          colors: [
                                    AppTheme.primaryGreen,
                                    AppTheme.secondaryGreen
                                  ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight))),
                              Positioned.fill(
                                  child: CustomPaint(
                                      painter: NatureBackgroundPainter(
                                          color1: Colors.white
                                              .withValues(alpha: 0.1),
                                          color2: Colors.white
                                              .withValues(alpha: 0.05),
                                          accent: AppTheme.accentGold
                                              .withValues(alpha: 0.2)))),
                            ],
                          ),
                        ),
                      ),
                      _wrapConstrained(
                        context,
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                                16.0,
                                16.0,
                                16.0,
                                120.0 + MediaQuery.of(context).padding.bottom),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSummaryCard(
                                        context, state.currentUser.debtAmount)
                                    .animate()
                                    .slideY(
                                        begin: 0.2, end: 0, duration: 400.ms),
                                const SizedBox(height: 32),
                                Text('SỐ TIỀN THANH TOÁN',
                                    style: TextStyle(
                                        color: AppTheme.textGrey,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 1.2)),
                                const SizedBox(height: 16),
                                _buildPaymentInput(context, state),
                                const SizedBox(height: 48),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: state.status ==
                                            DebtPaymentStatus.loading
                                        ? null
                                        : () => context
                                            .read<DebtPaymentCubit>()
                                            .createDebtPaymentOrder(),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 18),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                      elevation: 8,
                                      shadowColor: AppTheme.primaryGreen
                                          .withValues(alpha: 0.4),
                                    ),
                                    child: state.status ==
                                            DebtPaymentStatus.loading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2))
                                        : const Text('TẠO LỆNH THANH TOÁN',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.1)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Hàm hỗ trợ bọc các thành phần cần giới hạn chiều rộng trên Web
  Widget _wrapConstrained(BuildContext context, Widget sliver) {
    if (!Responsive.isDesktop(context)) return sliver;
    final double screenWidth = MediaQuery.of(context).size.width;
    const double maxWidth = 900;
    if (screenWidth <= maxWidth) return sliver;

    final double padding = (screenWidth - maxWidth) / 2;
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      sliver: sliver,
    );
  }

  Widget _buildSummaryCard(BuildContext context, double debtAmount) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Công nợ hiện tại',
                    style: TextStyle(fontSize: 16, color: AppTheme.textDark)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.account_balance_wallet_outlined,
                      color: AppTheme.errorRed),
                )
              ],
            ),
            const SizedBox(height: 12),
            Text(
              currencyFormat.format(debtAmount),
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.errorRed),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Vui lòng thanh toán đúng hạn',
                  style: TextStyle(fontSize: 12, color: AppTheme.textGrey)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInput(BuildContext context, DebtPaymentState state) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter()
              ],
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen),
              decoration: const InputDecoration(
                suffixText: 'đ',
                border: InputBorder.none,
                hintText: '0',
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context
                    .read<DebtPaymentCubit>()
                    .updateAmountToPay(state.currentUser.debtAmount),
                child: const Text('TRẢ HẾT TOÀN BỘ'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
