// lib/features/orders/presentation/pages/my_orders_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/core/theme/nature_background_painter.dart';
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
        backgroundColor: AppTheme.backgroundLight,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 120.0,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.primaryGreen,
                leading: const BackButton(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: const Text('Đơn hàng của tôi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
                            color1: Colors.white.withValues(alpha: 0.1),
                            color2: Colors.white.withValues(alpha: 0.05),
                            accent: AppTheme.accentGold.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    labelColor: AppTheme.primaryGreen,
                    unselectedLabelColor: AppTheme.textGrey,
                    indicatorColor: AppTheme.primaryGreen,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: [
                      _buildTabWithBadge(context, 'Chờ duyệt', context.select((MyOrdersCubit cubit) => cubit.state.pendingApprovalOrders.length)),
                      _buildTabWithBadge(context, 'Đang xử lý', context.select((MyOrdersCubit cubit) => cubit.state.ongoingOrders.length)),
                      const Tab(text: 'Lịch sử'),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
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
      ),
    );
  }

  Tab _buildTabWithBadge(BuildContext context, String text, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.errorRed,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.backgroundLight, // Nền trùng với background app
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(emptyMessage, style: const TextStyle(fontSize: 16, color: AppTheme.textGrey), textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => context.read<MyOrdersCubit>().fetchMyOrders(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: orders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final order = orders[index];
          return _OrderCard(order: order).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  (Color, String, String?) _getStatusInfo(OrderModel order) {
    if (order.returnInfo != null) {
      switch (order.returnInfo!.returnStatus) {
        case 'pending_approval': return (Colors.purple, 'Đang chờ duyệt đổi/trả', null);
        case 'approved': return (Colors.blue, 'Đã duyệt đổi/trả', 'Công ty sẽ liên hệ');
        case 'rejected': return (Colors.red, 'Từ chối đổi/trả', 'Xem chi tiết');
        case 'completed': return (AppTheme.primaryGreen, 'Đã đổi/trả xong', null);
      }
    }
    switch (order.status) {
      case 'pending_approval': return (Colors.blue, 'Chờ phê duyệt', null);
      case 'pending': return (Colors.orange, 'Chờ xử lý', null);
      case 'processing': return (Colors.cyan, 'Đang xử lý', null);
      case 'shipped': return (Colors.teal, 'Đang giao', null);
      case 'completed': return (AppTheme.primaryGreen, 'Hoàn thành', null);
      case 'cancelled': return (Colors.grey, 'Đã hủy', null);
      case 'rejected': return (Colors.red, 'Đã từ chối', null);
      default: return (Colors.grey, 'Không xác định', null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(order);
    final statusColor = statusInfo.$1;
    final statusText = statusInfo.$2;
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          if (order.id != null) {
            Navigator.of(context).push(OrderDetailPage.route(order.id!));
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Mã đơn + Trạng thái
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '#${order.id?.substring(0, 6).toUpperCase() ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Nội dung: Ngày đặt + Số lượng
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppTheme.textGrey),
                  const SizedBox(width: 6),
                  Text(
                    order.createdAt != null ? dateFormat.format(order.createdAt!.toDate()) : 'N/A',
                    style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.shopping_bag_outlined, size: 16, color: AppTheme.textGrey),
                  const SizedBox(width: 6),
                  Text(
                    '${order.items.length} sản phẩm',
                    style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
                  ),
                ],
              ),
              
              const Divider(height: 24),
              
              // Footer: Tổng tiền
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng thanh toán', style: TextStyle(color: AppTheme.textGrey)),
                  Text(
                    formatter.format(order.finalTotal),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
