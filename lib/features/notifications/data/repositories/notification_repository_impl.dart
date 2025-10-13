// lib/features/notifications/data/repositories/notification_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:piv_app/features/notifications/data/models/notification_model.dart';
import 'package:piv_app/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    // --- BẮT ĐẦU SỬA LỖI ---
    // Truy vấn vào đúng sub-collection "notifications" của user
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50) // Giới hạn 50 thông báo gần nhất
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return [];
      }
      return snapshot.docs
          .map((doc) => NotificationModel.fromSnap(doc))
          .toList();
    });
    // --- KẾT THÚC SỬA LỖI ---
  }

  @override
  Future<void> markAsRead(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }
}