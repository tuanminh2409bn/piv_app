import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/core/theme/nature_background_painter.dart';
import 'package:piv_app/data/models/address_model.dart';
import 'package:piv_app/data/models/order_item_model.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/data/models/payment_info_model.dart';
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/orders/presentation/bloc/order_detail_cubit.dart';
import 'package:piv_app/features/returns/presentation/pages/create_return_request_page.dart';
import 'package:piv_app/common/widgets/currency_input_formatter.dart'; 

class OrderDetailPage extends StatelessWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  static PageRoute<void> route(String orderId) {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (_) => sl<OrderDetailCubit>()..listenToOrderDetail(orderId),
        child: OrderDetailPage(orderId: orderId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrderDetailView(orderId: orderId);
  }
}

class OrderDetailView extends StatefulWidget {
  final String orderId;
  const OrderDetailView({super.key, required this.orderId});

  @override
  State<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<OrderDetailView> {
  late TextEditingController amountController;
  late TextEditingController voucherController;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
    voucherController = TextEditingController();
  }

  @override
  void dispose() {
    amountController.dispose();
    voucherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.select((AuthBloc bloc) =>
        bloc.state is AuthAuthenticated ? (bloc.state as AuthAuthenticated).user : null);
    final numberFormatter = NumberFormat.decimalPattern('vi_VN');

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: BlocConsumer<OrderDetailCubit, OrderDetailState>(
        listener: (context, state) {
          if (state.status == OrderDetailStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                  content: Text(state.errorMessage!), backgroundColor: AppTheme.errorRed));
            context.read<OrderDetailCubit>().clearError();
          }
          if (state.status == OrderDetailStatus.voucherError && state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                  content: Text(state.errorMessage!), backgroundColor: Colors.orange));
          }
          // Logic Auto-fill số tiền khi ở trạng thái chờ duyệt
          if (state.status == OrderDetailStatus.success &&
              state.order?.status == 'pending_approval') {
            final totalAmountToHandle = (state.order!.finalTotal +
                    state.order!.debtAmount -
                    state.voucherDiscount)
                .clamp(0, double.infinity)
                .toDouble();
            final formattedTotal = numberFormatter.format(totalAmountToHandle);
            if (amountController.text != formattedTotal) {
              amountController.value = TextEditingValue(
                  text: formattedTotal,
                  selection: TextSelection.collapsed(offset: formattedTotal.length));
            }
            if (state.appliedVoucher == null && voucherController.text.isNotEmpty) {
              voucherController.clear();
            }
          }
        },
        builder: (context, state) {
          if (state.status == OrderDetailStatus.loading ||
              state.status == OrderDetailStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.order == null) {
            return Center(
                child: Text(state.errorMessage ?? 'Không thể tải chi tiết đơn hàng.',
                    style: const TextStyle(color: AppTheme.textGrey)));
          }

          final order = state.order!;
          final totalAmountToHandle = (order.finalTotal + order.debtAmount - state.voucherDiscount)
              .clamp(0, double.infinity)
              .toDouble();

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _buildSliverAppBar(context, order),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatusCard(context, order),
                            const SizedBox(height: 16),

                            if (currentUser != null && order.status == 'pending_approval') ...[
                              _buildDebtInfoCard(context, currentUser.debtAmount.toDouble()),
                              const SizedBox(height: 16),
                            ],

                            if (order.shippingDate != null) ...[
                              _buildInfoCard(
                                  context,
                                  'Thông tin giao hàng',
                                  Icons.local_shipping_outlined,
                                  _ShippingInfo(shippingDate: order.shippingDate!.toDate())),
                              const SizedBox(height: 16),
                            ],

                            if (order.paymentStatus == 'unpaid' &&
                                order.status != 'pending_approval') ...[
                              // Nếu là chủ đơn hàng (Khách hàng) -> Hiện mã QR
                              if (currentUser?.id == order.userId && state.paymentInfo != null) ...[
                                _buildInfoCard(
                                    context,
                                    'Thông tin thanh toán',
                                    Icons.qr_code_scanner,
                                    _PaymentQrInfo(paymentInfo: state.paymentInfo!, order: order)),
                              ]
                              // Nếu là Nhân viên/Admin -> Chỉ hiện thông báo
                              else if (currentUser?.id != order.userId) ...[
                                _buildInfoCard(
                                    context,
                                    'Thông tin thanh toán',
                                    Icons.info_outline,
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Khách hàng chưa thực hiện thanh toán/chuyển khoản.',
                                              style: TextStyle(
                                                  color: Colors.orange.shade800,
                                                  fontWeight: FontWeight.w500,
                                                  fontStyle: FontStyle.italic),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                              ],
                              const SizedBox(height: 16),
                            ],

                            _buildInfoCard(
                                context,
                                'Địa chỉ nhận hàng',
                                Icons.location_on_outlined,
                                _AddressInfo(address: order.shippingAddress)),
                            const SizedBox(height: 16),

                            _buildInfoCard(context, 'Sản phẩm', Icons.shopping_bag_outlined,
                                _OrderItemsList(items: order.items)),
                            const SizedBox(height: 16),

                            _buildInfoCard(
                                context,
                                'Thanh toán',
                                Icons.receipt_long_outlined,
                                _PaymentSummary(
                                    order: order,
                                    totalAmountToHandle: totalAmountToHandle,
                                    voucherDiscount: state.voucherDiscount)),

                            if (order.status == 'pending_approval') ...[
                              const SizedBox(height: 16),
                              _VoucherSection(voucherController: voucherController),
                              const SizedBox(height: 16),
                              _ApprovalPaymentInputSection(
                                  amountController: amountController,
                                  totalAmount: totalAmountToHandle,
                                  numberFormatter: numberFormatter),
                            ],

                            const SizedBox(height: 100), // Bottom padding for BottomBar
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                    ),
                  ),
                ],
              ),
              // Đã phục hồi Logic BottomBar
              _BottomBar(amountController: amountController, formKey: formKey),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, OrderModel order) {
    return SliverAppBar(
      expandedHeight: 120.0,
      pinned: true,
      backgroundColor: AppTheme.primaryGreen,
      leading: const BackButton(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
            'Đơn hàng #${order.id?.substring(0, 8).toUpperCase() ?? ''}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        background: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.secondaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: NatureBackgroundPainter(
                  color1: Colors.white.withOpacity(0.1),
                  color2: Colors.white.withOpacity(0.05),
                  accent: AppTheme.accentGold.withOpacity(0.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, OrderModel order) {
    final statusInfo = _getStatusInfo(order, context);
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusInfo.$1.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.info_outline, color: statusInfo.$1),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trạng thái đơn hàng',
                      style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                  Text(statusInfo.$2,
                      style: TextStyle(
                          color: statusInfo.$1, fontWeight: FontWeight.bold, fontSize: 16)),
                  if (statusInfo.$3 != null)
                    Text(statusInfo.$3!,
                        style: TextStyle(color: statusInfo.$1, fontSize: 12)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, IconData icon, Widget child) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(title.toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1)),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDebtInfoCard(BuildContext context, double debtAmount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Công nợ hiện tại: ',
                children: [
                  TextSpan(
                      text: formatter.format(debtAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
                style: TextStyle(color: Colors.orange.shade900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// LOGIC COMPONENTS (Restored & Styled)
// -----------------------------------------------------------------------------

class _PaymentSummary extends StatelessWidget {
  final OrderModel order;
  final double totalAmountToHandle;
  final double voucherDiscount;
  const _PaymentSummary({
    required this.order,
    required this.totalAmountToHandle,
    required this.voucherDiscount,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final bool isDebtPaymentOnly = order.items.isEmpty && order.debtAmount > 0;
    final double estimatedRemainingDebt = (order.finalTotal +
            order.debtAmount -
            order.paidAmount -
            voucherDiscount)
        .clamp(0, double.infinity)
        .toDouble();

    return Column(
      children: [
        if (!isDebtPaymentOnly) ...[
          _row('Tạm tính', formatter.format(order.subtotal)),
          const SizedBox(height: 8),
          _row('Phí vận chuyển', formatter.format(order.shippingFee)),
          const SizedBox(height: 8),
          if (voucherDiscount > 0)
            _row('Giảm giá voucher', '- ${formatter.format(voucherDiscount)}',
                color: Colors.green.shade700),
          if (order.commissionDiscount > 0) ...[
            const SizedBox(height: 8),
            _row('Chiết khấu', '- ${formatter.format(order.commissionDiscount)}',
                color: Colors.green.shade700),
          ],
          const Divider(height: 24),
          _row('Tiền hàng đơn này', formatter.format(order.finalTotal), isBold: true),
          const SizedBox(height: 8),
        ],
        if (order.debtAmount > 0)
          _row('Công nợ trước đơn', '+ ${formatter.format(order.debtAmount)}',
              color: Colors.red.shade700),
        const Divider(height: 24),
        if (isDebtPaymentOnly) ...[
          _row('Số tiền thanh toán nợ', formatter.format(order.paidAmount),
              isBold: true, size: 16, color: AppTheme.primaryGreen),
        ] else ...[
          _row('Tổng cộng cần xử lý', formatter.format(totalAmountToHandle),
              isBold: true, size: 16, color: AppTheme.primaryGreen),
        ],
        const SizedBox(height: 8),
        _row('Đã thanh toán (đơn này)', formatter.format(order.paidAmount),
            isBold: true, color: Colors.blue.shade700),
        const SizedBox(height: 8),
        _row(
          'Công nợ còn lại (dự kiến)',
          formatter.format(order.status == 'pending_approval'
              ? estimatedRemainingDebt
              : order.remainingDebt),
          isBold: true,
          color: (order.status == 'pending_approval'
                      ? estimatedRemainingDebt
                      : order.remainingDebt) >
                  0
              ? Colors.red.shade700
              : Colors.green.shade700,
        ),
        const SizedBox(height: 16),
        _row('Trạng thái TT', _getPaymentStatusText(order.paymentStatus),
            isBold: true, color: _getPaymentStatusColor(order.paymentStatus)),
      ],
    );
  }

  Widget _row(String label, String value,
      {bool isBold = false, double size = 14, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 2,
          child: Text(label, style: TextStyle(fontSize: size, color: AppTheme.textGrey)),
        ),
        const SizedBox(width: 16),
        Flexible(
          flex: 3,
          child: Text(value,
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontSize: size,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? Colors.black87)),
        ),
      ],
    );
  }
}

class _VoucherSection extends StatefulWidget {
  final TextEditingController voucherController;
  const _VoucherSection({required this.voucherController});

  @override
  State<_VoucherSection> createState() => _VoucherSectionState();
}

class _VoucherSectionState extends State<_VoucherSection> {
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _isButtonEnabled = widget.voucherController.text.trim().isNotEmpty;
    widget.voucherController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    widget.voucherController.removeListener(_updateButtonState);
    super.dispose();
  }

  void _updateButtonState() {
    final newState = widget.voucherController.text.trim().isNotEmpty;
    if (_isButtonEnabled != newState) {
      setState(() {
        _isButtonEnabled = newState;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderDetailCubit, OrderDetailState>(
      buildWhen: (prev, current) =>
          prev.appliedVoucher != current.appliedVoucher ||
          prev.status != current.status,
      builder: (context, state) {
        final cubit = context.read<OrderDetailCubit>();
        final bool isLoadingVoucher = state.status == OrderDetailStatus.applyingVoucher;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.confirmation_number_outlined,
                        size: 18, color: AppTheme.primaryGreen),
                    const SizedBox(width: 8),
                    const Text('MÃ GIẢM GIÁ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.1)),
                  ],
                ),
                const SizedBox(height: 16),
                state.appliedVoucher != null
                    ? _buildAppliedVoucherCard(context, state.appliedVoucher!, cubit)
                    : _buildVoucherInput(context, widget.voucherController, cubit,
                        isLoadingVoucher, _isButtonEnabled),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoucherInput(BuildContext context, TextEditingController controller,
      OrderDetailCubit cubit, bool isLoading, bool isButtonEnabled) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: !isLoading,
            decoration: const InputDecoration(
              labelText: 'Nhập mã giảm giá (nếu có)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _updateButtonState(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: isLoading || !isButtonEnabled
              ? null
              : () {
                  cubit.applyVoucher(controller.text.trim());
                  FocusScope.of(context).unfocus();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Áp dụng'),
        ),
      ],
    );
  }

  Widget _buildAppliedVoucherCard(
      BuildContext context, VoucherModel voucher, OrderDetailCubit cubit) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green),
      ),
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text('Đã áp dụng: ${voucher.id}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(voucher.description),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          tooltip: 'Xóa mã',
          onPressed: context.select((OrderDetailCubit c) =>
                  c.state.status == OrderDetailStatus.applyingVoucher)
              ? null
              : () => cubit.removeVoucher(),
        ),
      ),
    );
  }
}

class _ApprovalPaymentInputSection extends StatelessWidget {
  final TextEditingController amountController;
  final double totalAmount;
  final NumberFormat numberFormatter;

  const _ApprovalPaymentInputSection({
    required this.amountController,
    required this.totalAmount,
    required this.numberFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment_outlined, size: 18, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                const Text('XÁC NHẬN THANH TOÁN',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Tổng cần xử lý: ${formatter.format(totalAmount)}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Số tiền bạn muốn thanh toán',
                suffixText: 'đ',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              validator: (value) {
                if (value == null) return null;
                final cleanValue = value.replaceAll('.', '');
                if (cleanValue.isEmpty) return null;

                final amount = double.tryParse(cleanValue) ?? -1;
                if (amount < 0) {
                  return 'Số tiền không hợp lệ';
                }
                if (amount > totalAmount + 1000) { // Sai số nhỏ
                  return 'Không lớn hơn tổng cần xử lý';
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
                    final formattedTotal = numberFormatter.format(totalAmount);
                    amountController.value = TextEditingValue(
                      text: formattedTotal,
                      selection:
                          TextSelection.collapsed(offset: formattedTotal.length),
                    );
                    Form.of(context)?.validate();
                  },
                  child: const Text('TRẢ HẾT'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// BOTTOM BAR LOGIC (Restored)
// -----------------------------------------------------------------------------

class _BottomBar extends StatelessWidget {
  final TextEditingController amountController;
  final GlobalKey<FormState> formKey;
  const _BottomBar({required this.amountController, required this.formKey});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OrderDetailCubit>().state;
    final order = state.order;

    if (order == null) return const SizedBox.shrink();

    final authState = context.watch<AuthBloc>().state;
    bool isOrderOwner = false;
    if (authState is AuthAuthenticated) {
      isOrderOwner = authState.user.id == order.userId;
    }

    Widget? bottomWidget;

    if (isOrderOwner && order.status == 'pending_approval') {
      bottomWidget = _ApprovalActionButtonsOnly(
          order: order, amountController: amountController);
    } else if (isOrderOwner &&
        order.paymentStatus == 'unpaid' &&
        order.status != 'cancelled' &&
        order.status != 'rejected') {
      bottomWidget = _PaymentConfirmationButton(
          isLoading: state.status == OrderDetailStatus.updatingPaymentStatus);
    } else {
      final isReturnable = order.returnInfo == null ||
          order.returnInfo!.returnStatus == 'completed' ||
          order.returnInfo!.returnStatus == 'rejected';
      if (isOrderOwner && order.status == 'completed' && isReturnable) {
        bottomWidget = _ReturnExchangeButton(order: order);
      }
    }

    if (bottomWidget != null) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.all(16.0)
              .copyWith(bottom: 16.0 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -4))
              ]),
          child: bottomWidget,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _ApprovalActionButtonsOnly extends StatelessWidget {
  final OrderModel order;
  final TextEditingController amountController;

  const _ApprovalActionButtonsOnly(
      {required this.order, required this.amountController});

  void _showRejectionDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lý do từ chối'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Nhập lý do...'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('HỦY'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                context
                    .read<OrderDetailCubit>()
                    .rejectOrder(reasonController.text.trim());
                Navigator.of(dialogContext).pop();
              } else {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(
                    content: Text('Vui lòng nhập lý do.'),
                    backgroundColor: Colors.orange,
                  ));
              }
            },
            child: const Text('XÁC NHẬN TỪ CHỐI'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select((OrderDetailCubit cubit) =>
        cubit.state.status == OrderDetailStatus.updating ||
        cubit.state.status == OrderDetailStatus.applyingVoucher);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.close),
            label: const Text('TỪ CHỐI'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: isLoading ? null : () => _showRejectionDialog(context),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () {
                    double paidAmount = 0;
                    try {
                      paidAmount = double.parse(amountController.text
                          .replaceAll(RegExp(r'[^0-9]'), ''));
                    } catch (_) {}

                    // Tính tổng tiền cần xử lý (tương tự logic hiển thị)
                    final voucherDiscount = context.read<OrderDetailCubit>().state.voucherDiscount;
                    final totalAmountToHandle = (order.finalTotal +
                            order.debtAmount -
                            voucherDiscount)
                        .clamp(0, double.infinity)
                        .toDouble();

                    if (paidAmount > totalAmountToHandle) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Số tiền trả không thể lớn hơn tổng cần thanh toán')),
                      );
                      return;
                    }

                    context
                        .read<OrderDetailCubit>()
                        .approveOrder(paidAmount: paidAmount);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Đồng ý',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class _PaymentConfirmationButton extends StatelessWidget {
  final bool isLoading;
  const _PaymentConfirmationButton({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.check_circle_outline),
      label: Text(isLoading ? 'ĐANG GỬI...' : 'TÔI ĐÃ CHUYỂN KHOẢN'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: isLoading
          ? null
          : () {
              context.read<OrderDetailCubit>().notifyPaymentMade();
            },
    );
  }
}

class _ReturnExchangeButton extends StatelessWidget {
  final OrderModel order;
  const _ReturnExchangeButton({required this.order});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.sync_problem_outlined),
      label: const Text('YÊU CẦU ĐỔI/TRẢ HÀNG'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red.shade700,
        side: BorderSide(color: Colors.red.shade700),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: () {
        Navigator.of(context).push(CreateReturnRequestPage.route(order));
      },
    );
  }
}

// -----------------------------------------------------------------------------
// UI COMPONENTS
// -----------------------------------------------------------------------------

class _PaymentQrInfo extends StatefulWidget {
  final PaymentInfoModel paymentInfo;
  final OrderModel order;
  const _PaymentQrInfo({required this.paymentInfo, required this.order});

  @override
  State<_PaymentQrInfo> createState() => _PaymentQrInfoState();
}

class _PaymentQrInfoState extends State<_PaymentQrInfo> {
  int _selectedAccountIndex = 0; // 0: Công ty, 1: Cá nhân 1, 2: Cá nhân 2

  // --- THÔNG TIN TÀI KHOẢN ---
  // Để quét ra số tiền tự động, cả 3 tài khoản đều dùng cơ chế VietQR động
  List<Map<String, String>> get _accounts => [
    {
      'type': 'COMPANY',
      'label': 'TÀI KHOẢN CÔNG TY',
      'bank': 'Techcombank',
      'holder': 'CONG TY TNHH MTV PIV',
      'number': '1948883383',
      'bankId': 'TCB', 
    },
    {
      'type': 'PERSONAL',
      'label': 'TÀI KHOẢN CÁ NHÂN 1',
      'bank': 'VPBank', 
      'holder': 'LUONG MAI NAM',
      'number': '999888777666', 
      'bankId': 'VPB',
    },
    {
      'type': 'PERSONAL',
      'label': 'TÀI KHOẢN CÁ NHÂN 2',
      'bank': 'MB Bank',
      'holder': 'LUONG MAI NAM',
      'number': '0327284001',
      'bankId': 'MB',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final shortOrderId = widget.order.id?.substring(0, 8).toUpperCase() ?? 'DONHANG';
    final paymentContent = 'PIV DH $shortOrderId';
    final amount = widget.order.finalTotal;
    
    final selectedAcc = _accounts[_selectedAccountIndex];
    final bool isCompany = selectedAcc['type'] == 'COMPANY';

    // Tạo link VietQR động cho tất cả các tài khoản
    // template 'compact2' hiển thị mã QR kèm logo ngân hàng gọn đẹp
    final qrUrl = 'https://img.vietqr.io/image/${selectedAcc['bankId']}-${selectedAcc['number']}-compact2.png?amount=${amount.toInt()}&addInfo=${Uri.encodeComponent(paymentContent)}&accountName=${Uri.encodeComponent(selectedAcc['holder']!)}';

    return Column(
      children: [
        const Text('Chọn tài khoản chuyển khoản:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 12),
        
        // --- NÚT CHỌN TÀI KHOẢN ---
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_accounts.length, (index) {
              final acc = _accounts[index];
              final isSelected = _selectedAccountIndex == index;
              final isAccCompany = acc['type'] == 'COMPANY';

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(acc['label']!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (isAccCompany ? AppTheme.primaryGreen : Colors.blue))),
                      Text(acc['bank']!, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    if (selected) setState(() => _selectedAccountIndex = index);
                  },
                  selectedColor: isAccCompany ? AppTheme.primaryGreen : Colors.blue,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: isAccCompany ? AppTheme.primaryGreen : Colors.blue, width: 1.5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  showCheckmark: false,
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 24),

        // --- KHUNG HIỂN THỊ MÃ QR ---
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isCompany ? AppTheme.primaryGreen.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.2), width: 2),
            boxShadow: [
              BoxShadow(
                color: (isCompany ? AppTheme.primaryGreen : Colors.blue).withValues(alpha: 0.08),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              )
            ]
          ),
          child: Column(
            children: [
              // Badge phân biệt loại tài khoản
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isCompany ? AppTheme.primaryGreen : Colors.blue,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isCompany ? Icons.business : Icons.person, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      selectedAcc['label']!,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Ảnh QR
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  qrUrl,
                  height: 300,
                  width: 300,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : const SizedBox(height: 300, width: 300, child: Center(child: CircularProgressIndicator())),
                  errorBuilder: (context, error, stack) => const SizedBox(height: 300, width: 300, child: Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 40),
                      SizedBox(height: 8),
                      Text('Không thể tạo mã QR', style: TextStyle(color: Colors.grey)),
                    ],
                  ))),
                ),
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              
              // Thông tin văn bản bên dưới QR
              Text(selectedAcc['holder']!, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${selectedAcc['bank']} - ', style: const TextStyle(fontSize: 15, color: Colors.grey)),
                  SelectableText(selectedAcc['number']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // --- NỘI DUNG CHUYỂN KHOẢN (VẪN GIỮ ĐỂ KHÁCH KIỂM TRA) ---
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade300)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.amber.shade900),
                  const SizedBox(width: 8),
                  const Text('Nội dung chuyển khoản:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text(paymentContent,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.redAccent))),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: paymentContent));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã sao chép nội dung!'), behavior: SnackBarBehavior.floating));
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('SAO CHÉP'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      elevation: 0,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 4),
              const Text('* Quét mã QR để tự động điền thông tin này.', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShippingInfo extends StatelessWidget {
  final DateTime shippingDate;
  const _ShippingInfo({required this.shippingDate});
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, dd/MM/yyyy', 'vi_VN');
    return Text(dateFormat.format(shippingDate),
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500));
  }
}

class _AddressInfo extends StatelessWidget {
  final AddressModel address;
  const _AddressInfo({required this.address});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(address.recipientName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 4),
        Text(address.phoneNumber, style: const TextStyle(color: AppTheme.textGrey)),
        const SizedBox(height: 4),
        Text(address.fullAddress),
      ],
    );
  }
}

class _OrderItemsList extends StatelessWidget {
  final List<OrderItemModel> items;
  const _OrderItemsList({required this.items});
  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 24),
      itemBuilder: (context, index) {
        final item = items[index];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(item.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: item.packaging.toLowerCase().contains('thùng') 
                              ? AppTheme.primaryGreen.withOpacity(0.1) 
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: item.packaging.toLowerCase().contains('thùng') 
                                ? AppTheme.primaryGreen.withOpacity(0.3) 
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          item.packaging.toLowerCase().contains('thùng') ? 'THÙNG' : 'LẺ',
                          style: TextStyle(
                            color: item.packaging.toLowerCase().contains('thùng') ? AppTheme.primaryGreen : AppTheme.textGrey,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            '${item.quantity} ${item.packaging} (${item.unit} x ${formatter.format(item.price)})',
                            style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(formatter.format(item.subtotal),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// HELPER FUNCTIONS (Restored Logic)
// -----------------------------------------------------------------------------

  (Color, String, String?) _getStatusInfo(OrderModel order, BuildContext context) {  final returnRequest = context.read<OrderDetailCubit>().state.returnRequest;
  if (order.returnInfo != null) {
    switch (order.returnInfo!.returnStatus) {
      case 'pending_approval':
        return (Colors.purple.shade700, 'Đang chờ duyệt đổi/trả', null);
      case 'approved':
        return (Colors.blue.shade700, 'Đã duyệt đổi/trả', 'Công ty sẽ liên hệ để xử lý');
      case 'rejected':
        return (Colors.red.shade700, 'Từ chối đổi/trả', returnRequest?.rejectionReason ?? 'Không có lý do.');
      case 'completed':
        return (AppTheme.primaryGreen, 'Đã đổi/trả thành công', null);
    }
  }

  switch (order.status) {
    case 'pending_approval':
      return (Colors.blue.shade700, 'Chờ phê duyệt', null);
    case 'pending':
      return (Colors.orange.shade700, 'Chờ xử lý', null);
    case 'processing':
      return (Colors.cyan.shade700, 'Đang xử lý', null);
    case 'shipped':
      return (Colors.teal.shade700, 'Đang giao', null);
    case 'completed':
      return (AppTheme.primaryGreen, 'Hoàn thành', null);
    case 'cancelled':
      return (Colors.grey.shade700, 'Đã hủy', null);
    case 'rejected':
      return (Colors.red.shade700, 'Đã từ chối', order.rejectionReason);
    default:
      return (Colors.grey.shade700, 'Không xác định', null);
  }
}

String _getPaymentStatusText(String status) {
  switch (status) {
    case 'unpaid':
      return 'Chưa thanh toán';
    case 'verifying':
      return 'Đang chờ xác nhận';
    case 'paid':
      return 'Đã thanh toán';
    default:
      return status;
  }
}

Color _getPaymentStatusColor(String status) {
  switch (status) {
    case 'unpaid':
      return Colors.orange.shade700;
    case 'verifying':
      return Colors.blue.shade700;
    case 'paid':
      return Colors.green.shade700;
    default:
      return Colors.grey;
  }
}