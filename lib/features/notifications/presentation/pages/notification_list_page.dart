//lib/features/notifications/presentation/pages/notification_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/common/widgets/empty_state_widget.dart';
import 'package:piv_app/features/news/presentation/pages/news_detail_page.dart';
import 'package:piv_app/features/notifications/presentation/bloc/notification_cubit.dart';
import 'package:piv_app/features/notifications/presentation/bloc/notification_state.dart';
import 'package:piv_app/features/notifications/presentation/widgets/notification_list_item.dart';
import 'package:piv_app/features/orders/presentation/pages/order_detail_page.dart';
import 'package:piv_app/features/products/presentation/pages/product_detail_page.dart';

class NotificationListPage extends StatelessWidget {
  const NotificationListPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const NotificationListPage());
  }

  // [ĐÃ SỬA LỖI] Hàm điều hướng với cách gọi route chính xác
  void _handleNavigation(BuildContext context, String type, Map<String, dynamic> payload) {
    switch (type) {
    // Các loại thông báo liên quan đến Đơn hàng
      case 'order_status':
      case 'order_status_general':
      case 'order_approval_request':
      case 'order_approval_result':
      case 'new_order_for_rep':
      case 'new_order_for_admin':
        if (payload['orderId'] != null) {
          Navigator.of(context).push(
            OrderDetailPage.route(payload['orderId'] as String), // Sửa ở đây
          );
        }
        break;

    // Thông báo Sản phẩm mới
      case 'new_product':
        if (payload['productId'] != null) {
          Navigator.of(context).push(
            ProductDetailPage.route(payload['productId'] as String), // Sửa ở đây
          );
        }
        break;

    // Thông báo Tin tức mới
      case 'new_article':
        if (payload['articleId'] != null) {
          Navigator.of(context).push(
            NewsDetailPage.route(payload['articleId'] as String), // Sửa ở đây
          );
        }
        break;

    // Các loại thông báo khác không cần điều hướng (chỉ cần xem)
      default:
        print('Không có hành động điều hướng cho loại thông báo: $type');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        centerTitle: true,
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading || state is NotificationInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationError) {
            return Center(
              child: Text(
                'Đã xảy ra lỗi: ${state.message}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.notifications_off_outlined,
                message: 'Bạn chưa có thông báo nào.',
              );
            }

            return ListView.separated(
              itemCount: state.notifications.length,
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
                return NotificationListItem(
                  notification: notification,
                  onTap: () {
                    if (!notification.isRead) {
                      context.read<NotificationCubit>().markAsRead(notification.id);
                    }
                    _handleNavigation(context, notification.type, notification.payload);
                  },
                );
              },
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}