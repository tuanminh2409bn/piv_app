import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_orders_cubit.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const AdminHomePage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdminOrdersCubit>()..fetchAllOrders(),
      child: const AdminOrdersView(),
    );
  }
}

class AdminOrdersView extends StatelessWidget {
  const AdminOrdersView({super.key});

  // Hàm helper để lấy màu và text cho trạng thái đơn hàng
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
        title: const Text('Quản lý Đơn hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: BlocConsumer<AdminOrdersCubit, AdminOrdersState>(
        listener: (context, state) {
          if (state.status == AdminOrdersStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state.status == AdminOrdersStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.orders.isEmpty) {
            return const Center(child: Text('Không có đơn hàng nào.'));
          }

          return RefreshIndicator(
            onRefresh: () async => context.read<AdminOrdersCubit>().fetchAllOrders(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: state.orders.length,
              itemBuilder: (context, index) {
                final order = state.orders[index];
                return _buildOrderCard(context, order);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final statusInfo = _getStatusInfo(order.status, context);

    // Danh sách các trạng thái để admin chọn
    const List<String> statusOptions = ['pending', 'processing', 'shipped', 'completed', 'cancelled'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đơn hàng #${order.id?.substring(0, 8).toUpperCase() ?? 'N/A'}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Ngày đặt: ${dateFormat.format(order.createdAt!.toDate())}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const Divider(height: 24),

            _buildInfoRow('Khách hàng:', order.shippingAddress.recipientName, isBold: true),
            _buildInfoRow('Số điện thoại:', order.shippingAddress.phoneNumber),
            _buildInfoRow('Địa chỉ:', order.shippingAddress.fullAddress),
            const SizedBox(height: 12),
            _buildInfoRow('Tổng tiền:', currencyFormatter.format(order.total), isBold: true, valueColor: Theme.of(context).colorScheme.primary),

            const Divider(height: 24),

            // Phần cập nhật trạng thái
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Trạng thái:', style: Theme.of(context).textTheme.titleMedium),
                DropdownButton<String>(
                  value: order.status,
                  icon: const Icon(Icons.arrow_drop_down),
                  underline: Container(height: 2, color: statusInfo.$1),
                  style: TextStyle(color: statusInfo.$1, fontWeight: FontWeight.bold),
                  onChanged: (String? newStatus) {
                    if (newStatus != null && newStatus != order.status) {
                      context.read<AdminOrdersCubit>().updateOrderStatus(order.id!, newStatus);
                    }
                  },
                  items: statusOptions.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(_getStatusInfo(value, context).$2), // Hiển thị text tiếng Việt
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ', style: TextStyle(color: Colors.grey.shade700)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
