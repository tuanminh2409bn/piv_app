import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/features/orders/presentation/bloc/my_orders_cubit.dart';
// Import trang chi tiết đơn hàng
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

  (Color, String) _getStatusInfo(String status, BuildContext context) {
    // ... (hàm này không đổi)
    switch (status) {
      case 'pending': return (Colors.orange.shade700, 'Chờ xử lý');
      case 'processing': return (Colors.blue.shade700, 'Đang xử lý');
      case 'shipped': return (Colors.teal.shade700, 'Đang giao');
      case 'completed': return (Theme.of(context).colorScheme.primary, 'Hoàn thành');
      case 'cancelled': return (Colors.red.shade700, 'Đã hủy');
      default: return (Colors.grey.shade700, 'Không xác định');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi'),
      ),
      body: BlocBuilder<MyOrdersCubit, MyOrdersState>(
        builder: (context, state) {
          if (state.status == MyOrdersStatus.loading && state.orders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == MyOrdersStatus.error) {
            return Center(child: Text(state.errorMessage ?? 'Không thể tải đơn hàng.'));
          }

          if (state.orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Bạn chưa có đơn hàng nào', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => context.read<MyOrdersCubit>().fetchMyOrders(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: state.orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = state.orders[index];
                final statusInfo = _getStatusInfo(order.status, context);
                final statusColor = statusInfo.$1;
                final statusText = statusInfo.$2;
                final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
                final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    // ** CẬP NHẬT ĐIỀU HƯỚNG Ở ĐÂY **
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Đơn hàng #${order.id?.substring(0, 6).toUpperCase() ?? 'N/A'}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              )
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text('Ngày đặt: ${dateFormat.format(order.createdAt!.toDate())}', style: TextStyle(color: Colors.grey.shade700)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.receipt_long, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text('${order.items.length} sản phẩm', style: TextStyle(color: Colors.grey.shade700)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Tổng cộng: ${formatter.format(order.total)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
