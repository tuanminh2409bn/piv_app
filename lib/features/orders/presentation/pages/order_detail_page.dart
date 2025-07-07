import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/data/models/order_item_model.dart';
import 'package:piv_app/data/models/address_model.dart';
import 'package:piv_app/features/orders/presentation/bloc/order_detail_cubit.dart';
import 'package:piv_app/features/orders/presentation/pages/payment_webview_page.dart';

class OrderDetailPage extends StatelessWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  static PageRoute<void> route(String orderId) {
    return MaterialPageRoute<void>(
      builder: (_) => OrderDetailPage(orderId: orderId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrderDetailCubit>()..listenToOrderDetail(orderId),
      child: const OrderDetailView(),
    );
  }
}

class OrderDetailView extends StatelessWidget {
  const OrderDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderDetailCubit, OrderDetailState>(
      listener: (context, state) {
        if (state.status == OrderDetailStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red));
        }
        else if (state.status == OrderDetailStatus.paymentUrlCreated && state.paymentUrl != null) {
          Navigator.of(context).push<String?>(
            PaymentWebViewPage.route(state.paymentUrl!),
          ).then((responseCode) {
            if (responseCode == '00') {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Giao dịch thành công! Trạng thái đơn hàng sẽ sớm được cập nhật.'), backgroundColor: Colors.green)
              );
            } else if (responseCode != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Giao dịch không thành công hoặc đã bị hủy.'), backgroundColor: Colors.orange)
              );
            }
            context.read<OrderDetailCubit>().resetPaymentUrlStatus();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Chi tiết Đơn hàng')),
        body: BlocBuilder<OrderDetailCubit, OrderDetailState>(
          builder: (context, state) {
            if (state.status == OrderDetailStatus.loading || state.status == OrderDetailStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == OrderDetailStatus.error || state.order == null) {
              return Center(child: Text(state.errorMessage ?? 'Không thể tải chi tiết đơn hàng.'));
            }

            final order = state.order!;
            final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
            final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
            final statusInfo = _getStatusInfo(order.status, context);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderHeader(context, order, statusInfo, dateFormat),
                  const Divider(height: 32),
                  _buildSection(
                    context,
                    title: 'Địa chỉ giao hàng',
                    icon: Icons.location_on_outlined,
                    child: _buildAddressInfo(order.shippingAddress),
                  ),
                  const Divider(height: 32),
                  _buildSection(
                    context,
                    title: 'Danh sách sản phẩm',
                    icon: Icons.shopping_bag_outlined,
                    child: _buildOrderItemsList(order.items, currencyFormatter),
                  ),
                  const Divider(height: 32),
                  _buildSection(
                    context,
                    title: 'Tóm tắt thanh toán',
                    icon: Icons.receipt_long_outlined,
                    child: _buildPaymentSummary(context, order, currencyFormatter),
                  ),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: BlocBuilder<OrderDetailCubit, OrderDetailState>(
          builder: (context, state) {
            final order = state.order;
            final bool canPay = order != null && order.paymentMethod == 'COD' && order.paymentStatus != 'paid';
            final bool isCreatingUrl = state.status == OrderDetailStatus.creatingPaymentUrl;

            if (canPay) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  icon: isCreatingUrl
                      ? Container(width: 20, height: 20, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Icon(Icons.credit_card),
                  label: Text(isCreatingUrl ? 'Đang tạo link...' : 'Thanh toán Online qua VNPAY'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF005A9C),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: isCreatingUrl
                      ? null
                      : () {
                    context.read<OrderDetailCubit>().initiateOnlinePayment();
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  (Color, String) _getStatusInfo(String status, BuildContext context) {
    switch (status) {
      case 'pending':
        return (Colors.orange.shade700, 'Chờ xử lý');
      case 'processing':
        return (Colors.blue.shade700, 'Đang xử lý');
      case 'shipped':
        return (Colors.teal.shade700, 'Đang giao');
      case 'completed':
        return (Theme.of(context).colorScheme.primary, 'Hoàn thành');
      case 'cancelled':
        return (Colors.red.shade700, 'Đã hủy');
      default:
        return (Colors.grey.shade700, 'Không xác định');
    }
  }

  Widget _buildOrderHeader(BuildContext context, OrderModel order, (Color, String) statusInfo, DateFormat dateFormat) {
    final statusColor = statusInfo.$1;
    final statusText = statusInfo.$2;
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
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
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

  Widget _buildSection(BuildContext context, {required String title, required IconData icon, required Widget child}) {
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

  Widget _buildAddressInfo(AddressModel address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(address.recipientName, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(address.phoneNumber),
        Text(address.fullAddress),
      ],
    );
  }

  Widget _buildOrderItemsList(List<OrderItemModel> items, NumberFormat formatter) {
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

  Widget _buildPaymentSummary(BuildContext context, OrderModel order, NumberFormat formatter) {
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
        _buildSummaryRow(context, 'Phương thức', order.paymentMethod == 'COD' ? 'Thanh toán khi nhận hàng' : 'Đã thanh toán Online'),
      ],
    );
  }

  // <<< HÀM NÀY ĐÃ ĐƯỢC SỬA LẠI ĐỂ CHỐNG OVERFLOW >>>
  Widget _buildSummaryRow(BuildContext context, String label, String value, {bool isTotal = false, bool isDiscount = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 16), // Thêm khoảng cách
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end, // Canh lề phải cho giá trị
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isDiscount ? Colors.green.shade700 : (isTotal ? Theme.of(context).colorScheme.primary : Colors.black87),
            ),
          ),
        ),
      ],
    );
  }
}