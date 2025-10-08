// lib/features/notifications/data/models/notification_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final String id;
  // KHÔNG cần userId vì thông báo đã nằm trong sub-collection của user
  // final String userId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> payload;
  final bool isRead;
  final Timestamp createdAt;

  const NotificationModel({
    required this.id,
    // required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.payload,
    required this.isRead,
    required this.createdAt,
  });

  // --- BẮT ĐẦU SỬA LỖI ---
  // Làm cho việc parse dữ liệu an toàn hơn, chống lại các trường null
  factory NotificationModel.fromSnap(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>? ?? {}; // An toàn nếu data là null

    return NotificationModel(
      id: snap.id,
      title: data['title'] as String? ?? 'Không có tiêu đề', // Cung cấp giá trị mặc định
      body: data['body'] as String? ?? 'Không có nội dung', // Cung cấp giá trị mặc định
      type: data['type'] as String? ?? 'general', // Cung cấp giá trị mặc định
      // Kiểm tra kiểu dữ liệu của payload trước khi ép kiểu
      payload: data['payload'] is Map ? Map<String, dynamic>.from(data['payload']) : {},
      isRead: data['isRead'] as bool? ?? false, // Cung cấp giá trị mặc định
      // Cung cấp giá trị mặc định phòng trường hợp createdAt bị thiếu
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }
  // --- KẾT THÚC SỬA LỖI ---

  NotificationModel copyWith({ bool? isRead }) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      type: type,
      payload: payload,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, title, body, type, payload, isRead, createdAt];
}