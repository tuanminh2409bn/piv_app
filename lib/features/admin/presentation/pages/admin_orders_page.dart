// lib/features/admin/presentation/pages/admin_orders_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_orders_cubit.dart';
import 'package:piv_app/features/orders/presentation/pages/order_detail_page.dart';

// Enum để định nghĩa các bộ lọc một cách an toàn
enum OrderFilter { processing, completed, all }

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AdminOrdersCubit>()..fetchAllOrders(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý Đơn hàng'),
        ),
        body: const _AdminOrdersView(),
      ),
    );
  }
}

class _AdminOrdersView extends StatefulWidget {
  const _AdminOrdersView();

  @override
  State<_AdminOrdersView> createState() => _AdminOrdersViewState();
}

class _AdminOrdersViewState extends State<_AdminOrdersView> {
  OrderFilter _selectedFilter = OrderFilter.processing;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        context.read<AdminOrdersCubit>().searchOrders(_searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminOrdersCubit, AdminOrdersState>(
      listener: (context, state) {
        if (state.status == AdminOrdersStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red));
        }
      },
      builder: (context, state) {
        final List<OrderModel> displayedOrders;
        switch (_selectedFilter) {
          case OrderFilter.processing:
            displayedOrders = state.processingOrders;
            break;
          case OrderFilter.completed:
            displayedOrders = state.completedOrders;
            break;
          case OrderFilter.all:
            displayedOrders = state.visibleOrders;
            break;
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SegmentedButton<OrderFilter>(
                style: SegmentedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  selectedForegroundColor: Theme.of(context).colorScheme.onPrimary,
                  selectedBackgroundColor: Theme.of(context).colorScheme.primary,
                ),
                segments: <ButtonSegment<OrderFilter>>[
                  ButtonSegment(
                    value: OrderFilter.processing,
                    label: Text('Cần xử lý (${state.processingOrders.length})'),
                    icon: const Icon(Icons.pending_actions_outlined),
                  ),
                  ButtonSegment(
                    value: OrderFilter.completed,
                    label: Text('Hoàn thành (${state.completedOrders.length})'),
                    icon: const Icon(Icons.check_circle_outline),
                  ),
                  ButtonSegment(
                    value: OrderFilter.all,
                    label: Text('Tất cả (${state.visibleOrders.length})'),
                    icon: const Icon(Icons.inventory_2_outlined),
                  ),
                ],
                selected: {_selectedFilter},
                onSelectionChanged: (Set<OrderFilter> newSelection) {
                  setState(() => _selectedFilter = newSelection.first);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm theo mã ĐH, tên hoặc SĐT khách...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _searchController.clear(),
                  )
                      : null,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: state.status == AdminOrdersStatus.loading && displayedOrders.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : displayedOrders.isEmpty
                  ? Center(child: Text('Không có đơn hàng nào phù hợp.'))
                  : RefreshIndicator(
                onRefresh: () => context.read<AdminOrdersCubit>().fetchAllOrders(),
                child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                    itemCount: displayedOrders.length,
                    itemBuilder: (context, index) {
                      final order = displayedOrders[index];
                      return _buildOrderCard(context, order);
                    }),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- CÁC HÀM HELPER GIỮ NGUYÊN TỪ FILE GỐC CỦA BẠN ---
  // ... (Bạn có thể sao chép 3 hàm _buildOrderCard, _getStatusInfo, và _showStatusChangeConfirmationDialog từ tệp admin_home_page.dart cũ của bạn và dán vào đây)
  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final statusInfo = _getStatusInfo(order.status, context);
    const List<String> statusOptions = ['pending', 'processing', 'shipped', 'completed', 'cancelled'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (order.id != null) {
            Navigator.of(context).push(OrderDetailPage.route(order.id!));
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Mã đơn: #${order.id?.substring(0, 8).toUpperCase() ?? 'N/A'}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: statusInfo.$1.withOpacity(0.1), borderRadius: BorderRadius.circular(20),),
                    child: Text(statusInfo.$2, style: TextStyle(color: statusInfo.$1, fontWeight: FontWeight.bold, fontSize: 12)),
                  )
                ],
              ),
              const SizedBox(height: 4),
              if(order.createdAt != null)
                Text(
                    'Ngày đặt: ${dateFormat.format(order.createdAt!.toDate())}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)
                ),
              const Divider(height: 24),
              _buildInfoRow('Khách hàng:', order.shippingAddress.recipientName, isBold: true),
              _buildInfoRow('Số điện thoại:', order.shippingAddress.phoneNumber),
              _buildInfoRow('Địa chỉ:', order.shippingAddress.fullAddress),
              const SizedBox(height: 12),
              _buildInfoRow('Tổng tiền:', currencyFormatter.format(order.total), isBold: true, valueColor: Theme.of(context).colorScheme.primary),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cập nhật trạng thái:', style: TextStyle(fontWeight: FontWeight.w500)),
                  DropdownButton<String>(
                    value: order.status,
                    icon: const Icon(Icons.arrow_drop_down),
                    underline: Container(height: 2, color: statusInfo.$1),
                    onChanged: (String? newStatus) {
                      if (newStatus != null && newStatus != order.status) {
                        _showStatusChangeConfirmationDialog(
                          context,
                          orderId: order.id!,
                          newStatus: newStatus,
                          newStatusText: _getStatusInfo(newStatus, context).$2,
                        );
                      }
                    },
                    items: statusOptions.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                          value: value,
                          child: Text(_getStatusInfo(value, context).$2, style: TextStyle(color: _getStatusInfo(value, context).$1, fontWeight: FontWeight.bold))
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, String) _getStatusInfo(String status, BuildContext context) {
    switch (status) {
      case 'pending': return (Colors.orange.shade700, 'Chờ xử lý');
      case 'processing': return (Colors.blue.shade700, 'Đang xử lý');
      case 'shipped': return (Colors.teal.shade700, 'Đang giao');
      case 'completed': return (Theme.of(context).colorScheme.primary, 'Hoàn thành');
      case 'cancelled': return (Colors.red.shade700, 'Đã hủy');
      default: return (Colors.grey.shade700, 'Không xác định');
    }
  }

  void _showStatusChangeConfirmationDialog(BuildContext context, {
    required String orderId,
    required String newStatus,
    required String newStatusText,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận thay đổi'),
          content: Text('Bạn có chắc chắn muốn đổi trạng thái đơn hàng thành "$newStatusText"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('HỦY'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<AdminOrdersCubit>().updateOrderStatus(orderId, newStatus);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('XÁC NHẬN'),
            )
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ', style: TextStyle(color: Colors.grey.shade700)),
          Expanded(child: Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: valueColor))),
        ],
      ),
    );
  }
}