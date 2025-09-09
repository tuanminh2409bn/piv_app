import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> payload;
  final bool isRead;
  final Timestamp createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.payload,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromSnap(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    return NotificationModel(
      id: snap.id,
      userId: data['userId'] as String,
      title: data['title'] as String,
      body: data['body'] as String,
      type: data['type'] as String,
      payload: data['payload'] as Map<String, dynamic>,
      isRead: data['isRead'] as bool,
      createdAt: data['createdAt'] as Timestamp,
    );
  }

  // Thêm copyWith nếu cần
  NotificationModel copyWith({ bool? isRead }) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      payload: payload,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, title, body, type, payload, isRead, createdAt];
}