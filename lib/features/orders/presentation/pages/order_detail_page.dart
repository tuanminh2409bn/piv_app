// lib/features/orders/presentation/pages/order_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/address_model.dart';
import 'package:piv_app/data/models/order_item_model.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/data/models/payment_info_model.dart';
import 'package:piv_app/data/models/user_model.dart';
// +++ THÊM IMPORT VOUCHER MODEL +++
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';
// +++ KẾT THÚC THÊM +++
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/orders/presentation/bloc/order_detail_cubit.dart';
import 'package:piv_app/features/returns/presentation/pages/create_return_request_page.dart';
import 'package:piv_app/features/checkout/presentation/pages/checkout_page.dart'; // Để sử dụng CurrencyInputFormatter

class OrderDetailPage extends StatelessWidget {
  // ... (Constructor và route giữ nguyên) ...
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
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    // +++ THÊM CONTROLLER CHO VOUCHER +++
    final voucherController = TextEditingController();
    // +++ KẾT THÚC THÊM +++

    // Dispose controllers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        amountController.dispose();
        voucherController.dispose(); // Dispose voucher controller
      }
    });

    return OrderDetailView(
      amountController: amountController,
      formKey: formKey,
      voucherController: voucherController, // Truyền voucher controller
    );
  }
}

class OrderDetailView extends StatelessWidget {
  final TextEditingController amountController;
  final GlobalKey<FormState> formKey;
  // +++ NHẬN VOUCHER CONTROLLER +++
  final TextEditingController voucherController;
  const OrderDetailView({
    super.key,
    required this.amountController,
    required this.formKey,
    required this.voucherController, // Thêm vào constructor
  });
  // +++ KẾT THÚC NHẬN +++

  @override
  Widget build(BuildContext context) {
    // ... (Lấy currentUser, formatters giữ nguyên) ...
    final currentUser = context.select((AuthBloc bloc) =>
    bloc.state is AuthAuthenticated ? (bloc.state as AuthAuthenticated).user : null);
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final numberFormatter = NumberFormat.decimalPattern('vi_VN');

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết Đơn hàng')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: BlocConsumer<OrderDetailCubit, OrderDetailState>(
          listener: (context, state) {
            // ... (listener xử lý error giữ nguyên) ...
            if (state.status == OrderDetailStatus.error && state.errorMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red));
              context.read<OrderDetailCubit>().emit(state.copyWith(status: OrderDetailStatus.success, clearError: true));
            }
            // Xử lý lỗi voucher riêng
            if (state.status == OrderDetailStatus.voucherError && state.errorMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.orange));
              // Cubit đã tự reset về success sau khi emit voucherError
            }

            // Cập nhật amountController
            if (state.status == OrderDetailStatus.success && state.order?.status == 'pending_approval') {
              // --- SỬA ĐỔI: Tính totalAmountToHandle bao gồm voucherDiscount ---
              final totalAmountToHandle = (state.order!.finalTotal + state.order!.debtAmount - state.voucherDiscount).clamp(0, double.infinity).toDouble();
              final formattedTotal = numberFormatter.format(totalAmountToHandle);
              if (amountController.text != formattedTotal) {
                amountController.value = TextEditingValue(
                  text: formattedTotal,
                  selection: TextSelection.collapsed(offset: formattedTotal.length),
                );
              }
              // Xóa text trong voucher controller nếu voucher bị remove từ state
              if (state.appliedVoucher == null && voucherController.text.isNotEmpty) {
                voucherController.clear();
              }
              // --- KẾT THÚC SỬA ĐỔI ---
            }
          },
          builder: (context, state) {
            // ... (Phần loading và kiểm tra order null giữ nguyên) ...
            if (state.status == OrderDetailStatus.loading || state.status == OrderDetailStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.order == null) {
              return Center(child: Text(state.errorMessage ?? 'Không thể tải chi tiết đơn hàng.'));
            }


            final order = state.order!;
            // --- SỬA ĐỔI: Tính totalAmountToHandle bao gồm voucherDiscount ---
            final totalAmountToHandle = (order.finalTotal + order.debtAmount - state.voucherDiscount).clamp(0, double.infinity).toDouble();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ... (_OrderHeader, Công nợ hiện tại, _ShippingInfo, _PaymentQrInfo, _AddressInfo, _OrderItemsList giữ nguyên) ...
                    _OrderHeader(order: order, placedByUser: state.placedByUser),
                    const Divider(height: 32),

                    if (currentUser != null && order.status == 'pending_approval') ...[
                      _Section(
                        title: 'Thông tin công nợ',
                        icon: Icons.account_balance_wallet_outlined,
                        child: Text(
                          'Công nợ hiện tại của bạn: ${formatter.format(currentUser.debtAmount.toDouble())}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                        ),
                      ),
                      const Divider(height: 32),
                    ],

                    if (order.shippingDate != null) ...[
                      _Section(
                        title: 'Thông tin giao hàng',
                        icon: Icons.local_shipping_outlined,
                        child: _ShippingInfo(shippingDate: order.shippingDate!.toDate()),
                      ),
                      const Divider(height: 32),
                    ],
                    if (order.paymentStatus == 'unpaid' && order.status != 'pending_approval' && state.paymentInfo != null) ...[
                      _Section(
                        title: 'Thông tin thanh toán',
                        icon: Icons.qr_code_scanner,
                        child: _PaymentQrInfo(paymentInfo: state.paymentInfo!, order: order),
                      ),
                      const Divider(height: 32),
                    ],
                    _Section(
                      title: 'Địa chỉ giao hàng',
                      icon: Icons.location_on_outlined,
                      child: _AddressInfo(address: order.shippingAddress),
                    ),
                    const Divider(height: 32),
                    _Section(
                      title: 'Danh sách sản phẩm',
                      icon: Icons.shopping_bag_outlined,
                      child: _OrderItemsList(items: order.items),
                    ),
                    const Divider(height: 32),

                    _Section(
                      title: 'Tóm tắt đơn hàng',
                      icon: Icons.receipt_long_outlined,
                      // +++ TRUYỀN THÊM voucherDiscount VÀO _PaymentSummary +++
                      child: _PaymentSummary(
                        order: order,
                        totalAmountToHandle: totalAmountToHandle,
                        voucherDiscount: state.voucherDiscount, // Truyền voucher discount từ state
                      ),
                    ),

                    // +++ THÊM PHẦN VOUCHER KHI CẦN DUYỆT +++
                    if (order.status == 'pending_approval') ...[
                      const Divider(height: 32),
                      _VoucherSection(voucherController: voucherController), // Widget mới
                    ],
                    // +++ KẾT THÚC THÊM +++

                    if (order.status == 'pending_approval') ...[
                      const Divider(height: 32),
                      _ApprovalPaymentInputSection(
                        amountController: amountController,
                        totalAmount: totalAmountToHandle, // Đã bao gồm voucher
                        numberFormatter: numberFormatter,
                      ),
                      const SizedBox(height: 120),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _BottomBar(
          amountController: amountController,
          formKey: formKey
      ),
    );
  }
}

// --- WIDGETS ---

// ... (_OrderHeader, _ShippingInfo, _OrderItemsList giữ nguyên) ...
class _OrderHeader extends StatelessWidget {
  final OrderModel order;
  final UserModel? placedByUser;
  const _OrderHeader({required this.order, this.placedByUser});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(order, context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Mã đơn: #${order.id?.substring(0, 8).toUpperCase() ?? 'N/A'}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: statusInfo.$1.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(statusInfo.$2, style: TextStyle(color: statusInfo.$1, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                if (statusInfo.$3 != null) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.35,
                    child: Text(
                      statusInfo.$3!,
                      style: TextStyle(color: statusInfo.$1, fontSize: 11),
                      textAlign: TextAlign.end,
                      softWrap: true,
                    ),
                  ),
                ]
              ],
            )
          ],
        ),
        const SizedBox(height: 8),
        if (order.createdAt != null)
          Text('Ngày đặt: ${dateFormat.format(order.createdAt!.toDate())}', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),

        if (placedByUser != null) ...[
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              text: 'Được tạo bởi: ',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              children: [
                TextSpan(
                  text: placedByUser!.displayName ?? 'Không rõ',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Giao hàng dự kiến: ',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            Expanded(
              child: Text(
                dateFormat.format(shippingDate),
                style: const TextStyle(fontWeight: FontWeight.bold),
                softWrap: true,
              ),
            ),
          ],
        ),
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
      itemBuilder: (context, index) {
        final item = items[index];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(item.imageUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 60, height: 60, color: Colors.grey.shade200)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'Đơn giá: ${formatter.format(item.price)} / ${item.unit}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  Text(
                    'Số lượng: ${item.quantity} thùng', // Giả sử đơn vị là thùng
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                formatter.format(item.subtotal),
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        );
      },
      separatorBuilder: (context, index) => const Divider(height: 24),
    );
  }
}

class _PaymentSummary extends StatelessWidget {
  final OrderModel order;
  final double totalAmountToHandle; // Tổng cần xử lý (đã trừ voucher)
  final double voucherDiscount;     // Số tiền voucher giảm
  const _PaymentSummary({
    required this.order,
    required this.totalAmountToHandle,
    required this.voucherDiscount, // Nhận voucherDiscount
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final bool isDebtPaymentOnly = order.items.isEmpty && order.debtAmount > 0;

    // --- TÍNH TOÁN CÔNG NỢ DỰ KIẾN (ESTIMATED) BAO GỒM VOUCHER ---
    // Công nợ dự kiến = Tiền hàng + Nợ cũ - Tiền trả (hiện là 0) - Voucher giảm giá
    final double estimatedRemainingDebt = (order.finalTotal + order.debtAmount - order.paidAmount - voucherDiscount).clamp(0, double.infinity).toDouble();
    // --- KẾT THÚC TÍNH TOÁN ---

    return Column(
      children: [
        if (!isDebtPaymentOnly) ...[
          // ... (Tạm tính, Phí VC, Giảm giá voucher, Chiết khấu, Tiền hàng đơn này giữ nguyên) ...
          _buildSummaryRow(context, 'Tạm tính', formatter.format(order.subtotal)),
          const SizedBox(height: 8),
          _buildSummaryRow(context, 'Phí vận chuyển', formatter.format(order.shippingFee)),
          const SizedBox(height: 8),
          // Hiển thị voucher discount từ state
          if (voucherDiscount > 0)
            _buildSummaryRow(context, 'Giảm giá voucher', '- ${formatter.format(voucherDiscount)}', isDiscount: true),
          if (order.commissionDiscount > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(context, 'Chiết khấu', '- ${formatter.format(order.commissionDiscount)}', isDiscount: true),
          ],
          const Divider(height: 24),
          _buildSummaryRow(context, 'Tiền hàng đơn này', formatter.format(order.finalTotal), isBold: true),
          const SizedBox(height: 8),
        ],

        if (order.debtAmount > 0)
          _buildSummaryRow(context, 'Công nợ trước đơn', '+ ${formatter.format(order.debtAmount)}', isDebt: true),

        const Divider(height: 24),

        // Tổng cộng cần xử lý (đã bao gồm voucher)
        _buildSummaryRow(context, 'Tổng cộng cần xử lý', formatter.format(totalAmountToHandle), isTotal: true),
        const SizedBox(height: 8),

        _buildSummaryRow(context, 'Đã thanh toán (đơn này)', formatter.format(order.paidAmount), isBold: true, color: Colors.blue.shade700),
        const SizedBox(height: 8),

        // --- SỬA ĐỔI HIỂN THỊ CÔNG NỢ CÒN LẠI ---
        // Nếu đang chờ duyệt, hiển thị công nợ dự kiến vừa tính
        // Nếu đã duyệt hoặc trạng thái khác, hiển thị công nợ đã lưu trong order
        _buildSummaryRow(
            context,
            'Công nợ còn lại (dự kiến)',
            formatter.format(order.status == 'pending_approval' ? estimatedRemainingDebt : order.remainingDebt), // <-- Thay đổi ở đây
            isTotal: true,
            color: (order.status == 'pending_approval' ? estimatedRemainingDebt : order.remainingDebt) > 0
                ? Colors.red.shade700
                : Colors.green.shade700
        ),
        // --- KẾT THÚC SỬA ĐỔI ---

        const SizedBox(height: 16),
        _buildSummaryRow(context, 'Trạng thái TT', _getPaymentStatusText(order.paymentStatus), isBold: true, color: _getPaymentStatusColor(order.paymentStatus)),
      ],
    );
  }

  // ... (_buildSummaryRow giữ nguyên) ...
  Widget _buildSummaryRow(BuildContext context, String label, String value, {bool isTotal = false, bool isDiscount = false, bool isDebt = false, bool isBold = false, Color? color}) {
    Color defaultColor = Colors.black87;
    if (isDiscount) defaultColor = Colors.green.shade700;
    if (isDebt) defaultColor = Colors.red.shade700;
    if (isTotal) defaultColor = Theme.of(context).colorScheme.primary;

    final valueStyle = TextStyle(
      fontSize: isTotal ? 18 : 16,
      fontWeight: isTotal || isBold ? FontWeight.bold : FontWeight.w500,
      color: color ?? defaultColor,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start, // Align top để tránh nhảy dòng nếu label dài
      children: [
        Flexible(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
                fontSize: isTotal ? 17 : 15,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: Colors.grey.shade700
            ),
            softWrap: true,
          ),
        ),
        const SizedBox(width: 16), // Khoảng cách giữa label và value
        Flexible(
          flex: 3,
          child: Text(
            value,
            style: valueStyle,
            textAlign: TextAlign.end, // Căn phải
            softWrap: false, // Hạn chế value xuống dòng (nếu quá dài sẽ bị ...)
            overflow: TextOverflow.ellipsis, // Hiển thị ... nếu quá dài
          ),
        ),
      ],
    );
  }
}

// +++ WIDGET MỚI: _VoucherSection +++
class _VoucherSection extends StatefulWidget {
  final TextEditingController voucherController;
  const _VoucherSection({required this.voucherController});

  @override
  State<_VoucherSection> createState() => _VoucherSectionState();
}

class _VoucherSectionState extends State<_VoucherSection> {
  bool _isButtonEnabled = false; // Trạng thái local để quản lý nút

  @override
  void initState() {
    super.initState();
    // Khởi tạo trạng thái ban đầu
    _isButtonEnabled = widget.voucherController.text.trim().isNotEmpty;
    // Lắng nghe thay đổi text
    widget.voucherController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    // Gỡ listener khi widget bị hủy
    widget.voucherController.removeListener(_updateButtonState);
    super.dispose();
  }

  // Hàm cập nhật trạng thái nút
  void _updateButtonState() {
    // Chỉ setState nếu trạng thái thực sự thay đổi
    final newState = widget.voucherController.text.trim().isNotEmpty;
    if (_isButtonEnabled != newState) {
      setState(() {
        _isButtonEnabled = newState;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Vẫn dùng BlocBuilder để lấy voucher đã áp dụng và trạng thái loading
    return BlocBuilder<OrderDetailCubit, OrderDetailState>(
      buildWhen: (prev, current) =>
      prev.appliedVoucher != current.appliedVoucher ||
          prev.status != current.status,
      builder: (context, state) {
        final cubit = context.read<OrderDetailCubit>();
        final bool isLoadingVoucher = state.status == OrderDetailStatus.applyingVoucher;

        return _Section(
          title: 'Mã giảm giá',
          icon: Icons.confirmation_number_outlined,
          child: state.appliedVoucher != null
              ? _buildAppliedVoucherCard(context, state.appliedVoucher!, cubit)
          // Truyền trạng thái isLoading và isButtonEnabled vào hàm build input
              : _buildVoucherInput(context, widget.voucherController, cubit, isLoadingVoucher, _isButtonEnabled),
        );
      },
    );
  }

  // Sửa hàm này để nhận thêm isButtonEnabled
  Widget _buildVoucherInput(BuildContext context, TextEditingController controller, OrderDetailCubit cubit, bool isLoading, bool isButtonEnabled) {
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
            // Cập nhật lại isButtonEnabled khi người dùng submit (ví dụ: nhấn enter trên bàn phím ảo)
            // Mặc dù đã có listener, nhưng cách này đảm bảo trạng thái đúng khi submit
            onSubmitted: (_) => _updateButtonState(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          // Sử dụng isButtonEnabled (trạng thái local) kết hợp isLoading (trạng thái cubit)
          onPressed: isLoading || !isButtonEnabled // Disable nếu đang loading HOẶC nút không enabled
              ? null
              : () {
            cubit.applyVoucher(controller.text.trim());
            FocusScope.of(context).unfocus();
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            // Thêm style cho nút disabled để rõ ràng hơn
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: isLoading
              ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Áp dụng'),
        ),
      ],
    );
  }

  Widget _buildAppliedVoucherCard(BuildContext context, VoucherModel voucher, OrderDetailCubit cubit) {
    // ... (Hàm này giữ nguyên) ...
    return Card(
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
          // Disable nút xóa khi đang loading
          onPressed: context.select((OrderDetailCubit c) => c.state.status == OrderDetailStatus.applyingVoucher)
              ? null
              : () => cubit.removeVoucher(),
        ),
      ),
    );
  }
}


// ... (_ApprovalPaymentInputSection, _BottomBar, _ApprovalActionButtonsOnly giữ nguyên) ...
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
    return _Section(
      title: 'Xác nhận thanh toán',
      icon: Icons.payment_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hiển thị tổng sau khi đã trừ voucher (nếu có)
          Text('Tổng cần xử lý: ${formatter.format(totalAmount)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
              // --- SỬA LỖI VALIDATION: So sánh số chính xác ---
              // Cho phép nhập số lớn hơn totalAmount một chút để tránh lỗi làm tròn
              if (amount > totalAmount + 0.01) {
                return 'Không lớn hơn tổng cần xử lý';
              }
              // --- KẾT THÚC SỬA ---
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
                    selection: TextSelection.collapsed(offset: formattedTotal.length),
                  );
                  Form.of(context)?.validate();
                },
                child: const Text('TRẢ HẾT'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
          amountController: amountController,
          formKey: formKey
      );
    } else if (isOrderOwner && order.paymentStatus == 'unpaid' && order.status != 'cancelled' && order.status != 'rejected') {
      bottomWidget = _PaymentConfirmationButton(isLoading: state.status == OrderDetailStatus.updatingPaymentStatus);
    } else {
      final isReturnable = order.returnInfo == null ||
          order.returnInfo!.returnStatus == 'completed' ||
          order.returnInfo!.returnStatus == 'rejected';
      if (isOrderOwner && order.status == 'completed' && isReturnable) {
        bottomWidget = _ReturnExchangeButton(order: order);
      }
    }

    if (bottomWidget != null) {
      return Container(
        padding: const EdgeInsets.all(16.0).copyWith(bottom: 16.0 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -4))]
        ),
        child: bottomWidget,
      );
    }

    return const SizedBox.shrink();
  }
}

class _ApprovalActionButtonsOnly extends StatelessWidget {
  final TextEditingController amountController;
  final GlobalKey<FormState> formKey;
  const _ApprovalActionButtonsOnly({required this.amountController, required this.formKey});

  void _showRejectionDialog(BuildContext context) {
    // ... (Giữ nguyên) ...
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                // Gọi cubit từ context gốc (parent context)
                context.read<OrderDetailCubit>().rejectOrder(reasonController.text.trim());
                Navigator.of(dialogContext).pop();
              } else {
                ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('Vui lòng nhập lý do.'), backgroundColor: Colors.orange,));
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
    final isLoading = context.select((OrderDetailCubit cubit) => cubit.state.status == OrderDetailStatus.updating || cubit.state.status == OrderDetailStatus.applyingVoucher); // Thêm applyingVoucher

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
          child: ElevatedButton.icon(
            icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check),
            label: Text(isLoading ? 'ĐANG XỬ LÝ' : 'PHÊ DUYỆT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: isLoading ? null : () {
              if (formKey.currentState!.validate()) {
                final cleanValue = amountController.text.replaceAll('.', '');
                final paidAmount = double.tryParse(cleanValue) ?? 0.0;
                context.read<OrderDetailCubit>().approveOrder(paidAmount: paidAmount);
              } else {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(
                    content: Text('Vui lòng kiểm tra lại số tiền thanh toán.'),
                    backgroundColor: Colors.orange,
                  ));
              }
            },
          ),
        ),
      ],
    );
  }
}


// ... (_PaymentConfirmationButton, _ReturnExchangeButton, _PaymentQrInfo, _Section, _AddressInfo giữ nguyên) ...
class _PaymentConfirmationButton extends StatelessWidget {
  final bool isLoading;
  const _PaymentConfirmationButton({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: isLoading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
      onPressed: isLoading ? null : () {
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

class _PaymentQrInfo extends StatelessWidget {
  final PaymentInfoModel paymentInfo;
  final OrderModel order;
  const _PaymentQrInfo({required this.paymentInfo, required this.order});

  @override
  Widget build(BuildContext context) {
    final shortOrderId = order.id?.substring(0, 8).toUpperCase() ?? 'DONHANG';
    final paymentContent = 'PIV DH $shortOrderId';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Table(
          columnWidths: const {
            0: IntrinsicColumnWidth(),
            1: FlexColumnWidth(),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.top,
          children: [
            _buildTableRow('Ngân hàng:', paymentInfo.bankName),
            _buildTableRow('Chủ tài khoản:', paymentInfo.accountHolder),
            _buildTableRow('Số tài khoản:', paymentInfo.accountNumber),
          ],
        ),
        const SizedBox(height: 16),
        if (paymentInfo.qrCodeImageUrl.isNotEmpty)
          Center(
            child: Image.network(
              paymentInfo.qrCodeImageUrl,
              width: 200,
              height: 200,
              loadingBuilder: (context, child, progress) =>
              progress == null ? child : const Center(child: CircularProgressIndicator()),
              errorBuilder: (context, error, stack) => const Text('Lỗi tải mã QR'),
            ),
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade400)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nội dung chuyển khoản (bắt buộc):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(paymentContent, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red))),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy_all_outlined, size: 16),
                    label: const Text('Sao chép'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: paymentContent));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã sao chép nội dung chuyển khoản!'))
                      );
                    },
                  )
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  TableRow _buildTableRow(String title, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
          child: Text(title, style: TextStyle(color: Colors.grey.shade700)),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Section({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 28.0),
          child: child,
        ),
      ],
    );
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
        Text(address.recipientName, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(address.phoneNumber),
        Text(address.fullAddress),
      ],
    );
  }
}

// ... (Các hàm helper còn lại giữ nguyên) ...
(Color, String, String?) _getStatusInfo(OrderModel order, BuildContext context) {
  final returnRequest = context.read<OrderDetailCubit>().state.returnRequest;
  if (order.returnInfo != null) {
    switch (order.returnInfo!.returnStatus) {
      case 'pending_approval':
        return (Colors.purple.shade700, 'Đang chờ duyệt đổi/trả', null);
      case 'approved':
        return (Colors.blue.shade700, 'Đã duyệt đổi/trả', 'Công ty sẽ liên hệ để xử lý');
      case 'rejected':
        return (Colors.red.shade700, 'Từ chối đổi/trả', returnRequest?.rejectionReason ?? 'Không có lý do.');
      case 'completed':
        return (Theme.of(context).colorScheme.primary, 'Đã đổi/trả thành công', null);
    }
  }

  switch (order.status) {
    case 'pending_approval': return (Colors.blue.shade700, 'Chờ phê duyệt', null);
    case 'pending': return (Colors.orange.shade700, 'Chờ xử lý', null);
    case 'processing': return (Colors.cyan.shade700, 'Đang xử lý', null);
    case 'shipped': return (Colors.teal.shade700, 'Đang giao', null);
    case 'completed': return (Theme.of(context).colorScheme.primary, 'Hoàn thành', null);
    case 'cancelled': return (Colors.grey.shade700, 'Đã hủy', null);
    case 'rejected': return (Colors.red.shade700, 'Đã từ chối', order.rejectionReason);
    default: return (Colors.grey.shade700, 'Không xác định', null);
  }
}

String _getPaymentStatusText(String status) {
  switch(status) {
    case 'unpaid': return 'Chưa thanh toán';
    case 'verifying': return 'Đang chờ xác nhận';
    case 'paid': return 'Đã thanh toán';
    default: return status;
  }
}

Color _getPaymentStatusColor(String status) {
  switch(status) {
    case 'unpaid': return Colors.orange.shade700;
    case 'verifying': return Colors.blue.shade700;
    case 'paid': return Colors.green.shade700;
    default: return Colors.grey;
  }
}