// lib/features/orders/presentation/pages/order_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/data/models/order_item_model.dart';
import 'package:piv_app/data/models/address_model.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/orders/presentation/bloc/order_detail_cubit.dart';
import 'package:piv_app/features/orders/presentation/pages/payment_webview_page.dart';

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

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 120.0), // Tăng padding bottom để không bị che
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OrderHeader(order: order),
                  const Divider(height: 32),
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
                    title: 'Tóm tắt thanh toán',
                    icon: Icons.receipt_long_outlined,
                    child: _PaymentSummary(order: order),
                  ),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: const _BottomBar(),
      ),
    );
  }
}

// --- TẤT CẢ CÁC WIDGET BÊN DƯỚI ĐỀU ĐƯỢC TỔ CHỨC LẠI HOẶC THÊM MỚI ---

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderDetailCubit, OrderDetailState>(
      builder: (context, state) {
        final order = state.order;
        if (order == null) return const SizedBox.shrink();

        // Trường hợp 1: Đơn hàng đang chờ phê duyệt
        if (order.status == 'pending_approval') {
          return _ApprovalActionButtons(order: order);
        }

        // Trường hợp 2: Đơn hàng có thể thanh toán online
        final authState = context.watch<AuthBloc>().state;
        bool isOrderOwner = false;
        if (authState is AuthAuthenticated) {
          isOrderOwner = authState.user.id == order.userId;
        }
        final bool canPay = isOrderOwner &&
            order.paymentMethod == 'COD' &&
            order.paymentStatus != 'paid' &&
            !['completed', 'cancelled', 'rejected'].contains(order.status);

        if (canPay) {
          return _PaymentButton(isLoading: state.status == OrderDetailStatus.creatingPaymentUrl);
        }

        // Mặc định không hiển thị gì
        return const SizedBox.shrink();
      },
    );
  }
}

class _ApprovalActionButtons extends StatelessWidget {
  final OrderModel order;
  const _ApprovalActionButtons({required this.order});

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

class _PaymentButton extends StatelessWidget {
  final bool isLoading;
  const _PaymentButton({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        icon: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : const Icon(Icons.credit_card),
        label: Text(isLoading ? 'Đang tạo link...' : 'Thanh toán Online qua VNPAY'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: const Color(0xFF005A9C),
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        onPressed: isLoading ? null : () => context.read<OrderDetailCubit>().initiateOnlinePayment(),
      ),
    );
  }
}

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
        _buildSummaryRow(context, 'Phương thức', order.paymentMethod == 'COD' ? 'Thanh toán khi nhận hàng' : 'Đã thanh toán Online'),
      ],
    );
  }

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
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
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