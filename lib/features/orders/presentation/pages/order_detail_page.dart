import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/data/models/order_item_model.dart';
import 'package:piv_app/data/models/address_model.dart';
import 'package:piv_app/features/orders/presentation/bloc/order_detail_cubit.dart';

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
      // <<< THAY ĐỔI: Gọi listenToOrderDetail thay vì fetch >>>
      create: (_) => sl<OrderDetailCubit>()..listenToOrderDetail(orderId),
      child: const OrderDetailView(),
    );
  }
}

class OrderDetailView extends StatelessWidget {
  const OrderDetailView({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Đơn hàng'),
      ),
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
          final statusColor = statusInfo.$1;
          final statusText = statusInfo.$2;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0), // Tăng padding dưới để không bị che bởi nút
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderHeader(context, order, statusText, statusColor, dateFormat),
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
                  child: _buildPaymentSummary(order, currencyFormatter),
                ),
              ],
            ),
          );
        },
      ),
      // <<< THÊM BOTTOMNAVIGATIONBAR CHỨA NÚT THANH TOÁN >>>
      bottomNavigationBar: BlocBuilder<OrderDetailCubit, OrderDetailState>(
        builder: (context, state) {
          // Nút chỉ hiện ra khi có đơn hàng và trạng thái là "pending"
          if (state.order != null && state.order!.paymentMethod == 'COD' && state.order!.paymentStatus != 'paid') {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.credit_card),
                label: const Text('Thanh toán Online qua VNPAY'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF005A9C), // Màu của VNPAY
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  // TODO: Ở bước tiếp theo, chúng ta sẽ viết logic xử lý ở đây.
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sắp có: Gọi Cloud Function và mở cổng thanh toán!'))
                  );
                },
              ),
            );
          }
          // Nếu không thì không hiển thị gì cả
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // Các hàm _buildOrderHeader, _buildSection, _buildAddressInfo, _buildOrderItemsList giữ nguyên
  Widget _buildOrderHeader(BuildContext context, OrderModel order, String statusText, Color statusColor, DateFormat dateFormat) {
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
        if(order.createdAt != null) Text(
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
              child: Image.network(item.imageUrl, width: 60, height: 60, fit: BoxFit.cover,
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

  // <<< HÀM NÀY ĐƯỢC CẬP NHẬT HOÀN TOÀN >>>
  Widget _buildPaymentSummary(OrderModel order, NumberFormat formatter) {
    return Column(
      children: [
        _buildSummaryRow('Tạm tính', formatter.format(order.subtotal)),
        const SizedBox(height: 8),
        _buildSummaryRow('Phí vận chuyển', formatter.format(order.shippingFee)),
        const SizedBox(height: 8),
        // Hiển thị chiết khấu voucher (nếu có)
        if (order.discount > 0)
          _buildSummaryRow('Giảm giá voucher', '- ${formatter.format(order.discount)}', isDiscount: true),
        // Hiển thị chiết khấu hoa hồng (nếu có)
        if (order.commissionDiscount > 0) ...[
          const SizedBox(height: 8),
          _buildSummaryRow('Chiết khấu đại lý', '- ${formatter.format(order.commissionDiscount)}', isDiscount: true),
        ],
        const Divider(height: 24),
        // Sử dụng finalTotal nếu nó lớn hơn 0, ngược lại dùng total (dành cho các đơn hàng cũ chưa có finalTotal)
        _buildSummaryRow('Tổng cộng', formatter.format(order.finalTotal > 0 ? order.finalTotal : order.total), isTotal: true),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isDiscount ? Colors.green.shade700 : Colors.black87,
          ),
        ),
      ],
    );
  }
}