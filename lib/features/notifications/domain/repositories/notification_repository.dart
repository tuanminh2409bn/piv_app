import 'package:piv_app/features/notifications/data/models/notification_model.dart';

abstract class NotificationRepository {
  Stream<List<NotificationModel>> getUserNotifications(String userId);
  Future<void> markAsRead(String userId, String notificationId);
}