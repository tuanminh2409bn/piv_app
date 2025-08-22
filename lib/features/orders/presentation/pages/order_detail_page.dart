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
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/orders/presentation/bloc/order_detail_cubit.dart';

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
    return const OrderDetailView();
  }
}

class OrderDetailView extends StatelessWidget {
  const OrderDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết Đơn hàng')),
      body: BlocConsumer<OrderDetailCubit, OrderDetailState>(
        listener: (context, state) {
          if (state.status == OrderDetailStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red));
            // Reset lại trạng thái để không hiển thị lỗi liên tục
            context.read<OrderDetailCubit>().emit(state.copyWith(status: OrderDetailStatus.success, clearError: true));
          }
        },
        builder: (context, state) {
          if (state.status == OrderDetailStatus.loading || state.status == OrderDetailStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.order == null) {
            return Center(child: Text(state.errorMessage ?? 'Không thể tải chi tiết đơn hàng.'));
          }

          final order = state.order!;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 150.0), // Tăng padding bottom để không bị che
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OrderHeader(order: order),
                const Divider(height: 32),

                if (order.paymentStatus == 'unpaid' && order.status != 'pending_approval' && state.paymentInfo != null) ...[
                  _Section(
                    title: 'Thông tin thanh toán',
                    icon: Icons.qr_code_scanner,
                    child: _PaymentQrInfo(
                      paymentInfo: state.paymentInfo!,
                      order: order,
                    ),
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
                  child: _PaymentSummary(order: order),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const _BottomBar(),
    );
  }
}

// --- WIDGETS CHO PHẦN GIAO DIỆN ---

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderDetailCubit, OrderDetailState>(
      builder: (context, state) {
        final order = state.order;
        if (order == null) return const SizedBox.shrink();

        final authState = context.watch<AuthBloc>().state;
        bool isOrderOwner = false;
        if (authState is AuthAuthenticated) {
          isOrderOwner = authState.user.id == order.userId;
        }

        // Ưu tiên 1: Hiển thị nút phê duyệt nếu user là chủ đơn hàng và đơn hàng đang chờ duyệt
        if (isOrderOwner && order.status == 'pending_approval') {
          return const _ApprovalActionButtons();
        }

        // Ưu tiên 2: Hiển thị nút xác nhận đã thanh toán nếu user là chủ đơn hàng và đơn hàng chưa thanh toán
        if (isOrderOwner && order.paymentStatus == 'unpaid') {
          return _PaymentConfirmationButton(isLoading: state.status == OrderDetailStatus.updatingPaymentStatus);
        }

        // Mặc định không hiển thị gì
        return const SizedBox.shrink();
      },
    );
  }
}

class _ApprovalActionButtons extends StatelessWidget {
  const _ApprovalActionButtons();

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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
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
    final isLoading = context.select((OrderDetailCubit cubit) => cubit.state.status == OrderDetailStatus.updating);

    return Container(
      padding: const EdgeInsets.all(16.0).copyWith(bottom: 16.0 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -4))]
      ),
      child: Row(
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
                context.read<OrderDetailCubit>().approveOrder();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentConfirmationButton extends StatelessWidget {
  final bool isLoading;
  const _PaymentConfirmationButton({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0).copyWith(bottom: 16.0 + MediaQuery.of(context).padding.bottom),
      child: ElevatedButton.icon(
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
        ),
        onPressed: isLoading ? null : () {
          context.read<OrderDetailCubit>().notifyPaymentMade();
        },
      ),
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
        // --- SỬA LỖI: Sử dụng Table để căn chỉnh ---
        Table(
          columnWidths: const {
            0: IntrinsicColumnWidth(), // Cột 0 (nhãn) sẽ có độ rộng bằng nội dung dài nhất
            1: FlexColumnWidth(),      // Cột 1 (giá trị) sẽ chiếm phần còn lại
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



  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title: ', style: TextStyle(color: Colors.grey.shade700)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  final OrderModel order;
  const _OrderHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(order.status, context);
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusInfo.$1.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusInfo.$2,
                style: TextStyle(color: statusInfo.$1, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            )
          ],
        ),
        const SizedBox(height: 8),
        if (order.createdAt != null)
          Text(
            'Ngày đặt: ${dateFormat.format(order.createdAt!.toDate())}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
              child: Image.network(
                item.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(width: 60, height: 60, color: Colors.grey.shade200),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('SL: ${item.quantity}'),
                ],
              ),
            ),
            Text(formatter.format(item.price * item.quantity)),
          ],
        );
      },
      separatorBuilder: (context, index) => const Divider(height: 24),
    );
  }
}

class _PaymentSummary extends StatelessWidget {
  final OrderModel order;
  const _PaymentSummary({required this.order});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return Column(
      children: [
        _buildSummaryRow(context, 'Tạm tính', formatter.format(order.subtotal)),
        const SizedBox(height: 8),
        _buildSummaryRow(context, 'Phí vận chuyển', formatter.format(order.shippingFee)),
        const SizedBox(height: 8),
        if (order.discount > 0)
          _buildSummaryRow(context, 'Giảm giá voucher', '- ${formatter.format(order.discount)}', isDiscount: true),
        if (order.commissionDiscount > 0) ...[
          const SizedBox(height: 8),
          _buildSummaryRow(context, 'Chiết khấu đại lý', '- ${formatter.format(order.commissionDiscount)}', isDiscount: true),
        ],
        const Divider(height: 24),
        _buildSummaryRow(context, 'Tổng cộng', formatter.format(order.finalTotal > 0 ? order.finalTotal : order.total), isTotal: true),
        const SizedBox(height: 8),
        _buildSummaryRow(context, 'Thanh toán', _getPaymentStatusText(order.paymentStatus), isBold: true, color: _getPaymentStatusColor(order.paymentStatus)),
      ],
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value, {bool isTotal = false, bool isDiscount = false, bool isBold = false, Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal || isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal || isBold ? FontWeight.bold : FontWeight.w500,
              color: color ?? (isDiscount ? Colors.green.shade700 : (isTotal ? Theme.of(context).colorScheme.primary : Colors.black87)),
            ),
          ),
        ),
      ],
    );
  }
}

// --- HÀM HELPER: Được đưa ra ngoài để tất cả các widget có thể dùng ---
(Color, String) _getStatusInfo(String status, BuildContext context) {
  switch (status) {
    case 'pending_approval': return (Colors.blue.shade700, 'Chờ phê duyệt');
    case 'pending': return (Colors.orange.shade700, 'Chờ xử lý');
    case 'processing': return (Colors.cyan.shade700, 'Đang xử lý');
    case 'shipped': return (Colors.teal.shade700, 'Đang giao');
    case 'completed': return (Theme.of(context).colorScheme.primary, 'Hoàn thành');
    case 'cancelled': return (Colors.grey.shade700, 'Đã hủy');
    case 'rejected': return (Colors.red.shade700, 'Đã từ chối');
    default: return (Colors.grey.shade700, 'Không xác định');
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