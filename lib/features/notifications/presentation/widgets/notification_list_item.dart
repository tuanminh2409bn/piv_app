import 'package:flutter/material.dart';
import 'package:piv_app/features/notifications/data/models/notification_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationListItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationListItem({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Xác định icon dựa trên loại thông báo
    IconData _getIconForType(String type) {
      switch (type) {
        case 'order_status':
        case 'order_status_general':
        case 'order_approval_request':
        case 'order_approval_result':
          return Icons.receipt_long_outlined;
        case 'new_product':
          return Icons.new_releases_outlined;
        case 'new_article':
          return Icons.article_outlined;
        case 'account_approved':
          return Icons.person_add_alt_1_outlined;
        case 'manual_promo':
          return Icons.campaign_outlined;
        default:
          return Icons.notifications_outlined;
      }
    }

    final bool isUnread = !notification.isRead;
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        color: isUnread ? theme.primaryColor.withOpacity(0.05) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Icon(
              _getIconForType(notification.type),
              color: isUnread ? theme.primaryColor : theme.iconTheme.color?.withOpacity(0.6),
              size: 28,
            ),
            const SizedBox(width: 16.0),
            // Nội dung
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    notification.body, // Hiển thị toàn bộ nội dung
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    timeago.format(notification.createdAt.toDate(), locale: 'vi'),
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // Dấu chấm "chưa đọc"
            if (isUnread)
              Container(
                margin: const EdgeInsets.only(left: 12, top: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}