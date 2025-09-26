// lib/features/orders/presentation/pages/my_orders_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/features/orders/presentation/bloc/my_orders_cubit.dart';
import 'package:piv_app/features/orders/presentation/pages/order_detail_page.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const MyOrdersPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<MyOrdersCubit>(),
      child: const MyOrdersView(),
    );
  }
}

class MyOrdersView extends StatelessWidget {
  const MyOrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đơn hàng của tôi'),
          bottom: TabBar(
            // --- SỬA LỖI GIAO DIỆN TẠI ĐÂY ---
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            // ------------------------------------
            tabs: [
              _buildTabWithBadge(context, 'Chờ duyệt', context.select((MyOrdersCubit cubit) => cubit.state.pendingApprovalOrders.length)),
              _buildTabWithBadge(context, 'Đang xử lý', context.select((MyOrdersCubit cubit) => cubit.state.ongoingOrders.length)),
              const Tab(text: 'Lịch sử'),
            ],
          ),
        ),
        body: BlocBuilder<MyOrdersCubit, MyOrdersState>(
          builder: (context, state) {
            if (state.status == MyOrdersStatus.loading && state.ongoingOrders.isEmpty && state.pendingApprovalOrders.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == MyOrdersStatus.error) {
              return Center(child: Text(state.errorMessage ?? 'Không thể tải đơn hàng.'));
            }

            return TabBarView(
              children: [
                _OrderListView(orders: state.pendingApprovalOrders, emptyMessage: 'Không có đơn hàng nào cần bạn phê duyệt.'),
                _OrderListView(orders: state.ongoingOrders, emptyMessage: 'Không có đơn hàng nào đang được xử lý.'),
                _OrderListView(orders: state.completedOrders, emptyMessage: 'Chưa có đơn hàng nào trong lịch sử.'),
              ],
            );
          },
        ),
      ),
    );
  }

  Tab _buildTabWithBadge(BuildContext context, String text, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(color: Theme.of(context).colorScheme.onError, fontSize: 12),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class _OrderListView extends StatelessWidget {
  final List<OrderModel> orders;
  final String emptyMessage;

  const _OrderListView({required this.orders, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text(emptyMessage, style: const TextStyle(fontSize: 18), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => context.read<MyOrdersCubit>().fetchMyOrders(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: orders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = orders[index];
          return _OrderCard(order: order);
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  (Color, String, String?) _getStatusInfo(OrderModel order,
      BuildContext context) {
    if (order.returnInfo != null) {
      switch (order.returnInfo!.returnStatus) {
        case 'pending_approval':
          return (Colors.purple.shade700, 'Đang chờ duyệt đổi/trả', null);
        case 'approved':
          return (Colors.blue
              .shade700, 'Đã duyệt đổi/trả', 'Công ty sẽ liên hệ để xử lý');
        case 'rejected':
          return (Colors.red
              .shade700, 'Từ chối đổi/trả', 'Xem chi tiết để biết lý do');
        case 'completed':
          return (Theme
              .of(context)
              .colorScheme
              .primary, 'Đã đổi/trả thành công', null);
      }
    }

    // Nếu không có, hiển thị trạng thái đơn hàng như cũ
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
        return (Theme
            .of(context)
            .colorScheme
            .primary, 'Hoàn thành', null);
      case 'cancelled':
        return (Colors.grey.shade700, 'Đã hủy', null);
      case 'rejected':
        return (Colors.red.shade700, 'Đã từ chối', null);
      default:
        return (Colors.grey.shade700, 'Không xác định', null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(order, context);
    final statusColor = statusInfo.$1;
    final statusText = statusInfo.$2;
    final statusSubtext = statusInfo.$3;
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (order.id != null) {
            Navigator.of(context).push(OrderDetailPage.route(order.id!));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Đơn hàng #${order.id?.substring(0, 6).toUpperCase() ??
                          'N/A'}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                      if (statusSubtext != null) ...[
                        const SizedBox(height: 4),
                        Text(statusSubtext,
                            style: TextStyle(color: statusColor, fontSize: 11)),
                      ]
                    ],
                  )
                ],
              ),
              if (order.placedBy != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Được tạo bởi NVKD/Kế toán',
                    style: TextStyle(
                        color: Colors.blueGrey.shade700, fontSize: 13),
                  ),
                ),
              const Divider(height: 20),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14,
                      color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text('Ngày đặt: ${order.createdAt != null ? dateFormat.format(
                      order.createdAt!.toDate()) : 'N/A'}',
                      style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.receipt_long, size: 14,
                      color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text('${order.items.length} sản phẩm',
                      style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tổng cộng: ${formatter.format(order.finalTotal)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}