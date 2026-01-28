// lib/features/admin/presentation/pages/notification_history_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationHistoryPage extends StatelessWidget {
  const NotificationHistoryPage({super.key});

  // --- BẮT ĐẦU SỬA LỖI ---
  // Hàm trợ giúp để diễn giải đối tượng `target`
  String _getTargetDescription(Map<String, dynamic> targetData) {
    final type = targetData['type'];
    if (type == 'all') {
      return 'Tất cả Đại lý';
    }
    if (type == 'sales_rep_group') {
      final name = targetData['salesRepName'];
      return 'Đại lý của NVKD: ${name ?? 'Chưa xác định'}';
    }
    if (type == 'specific_users') {
        final names = targetData['recipientNames'];
        if (names != null && names is List && names.isNotEmpty) {
            return 'Khách hàng: ${names.join(", ")}';
        }
        return 'Khách hàng lẻ';
    }
    return 'Không rõ';
  }
  // --- KẾT THÚC SỬA LỖI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Thông Báo'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('manualNotifications')
            .orderBy('sentAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có thông báo nào được gửi.'));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + MediaQuery.of(context).padding.bottom),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index].data() as Map<String, dynamic>;
              final sentAt = (notification['sentAt'] as Timestamp).toDate();
              final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(sentAt);

              // --- BẮT ĐẦU SỬA LỖI ---
              // Lấy dữ liệu target một cách an toàn
              final targetData = notification['target'] as Map<String, dynamic>? ?? {};
              final targetDescription = _getTargetDescription(targetData);
              final recipientCount = notification['recipientCount']?.toString() ?? 'N/A';
              // --- KẾT THÚC SỬA LỖI ---

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  title: Text(notification['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(notification['body'] ?? ''),
                      const SizedBox(height: 10),
                      Text(
                        'Đối tượng: $targetDescription', // Hiển thị chuỗi đã được diễn giải
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Số người nhận: $recipientCount',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Thời gian: $formattedDate',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}