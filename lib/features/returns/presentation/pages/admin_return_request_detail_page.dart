// lib/features/returns/presentation/pages/admin_return_request_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/features/returns/data/models/return_request_model.dart';
import 'package:piv_app/features/returns/presentation/bloc/admin_returns_cubit.dart';

class AdminReturnRequestDetailPage extends StatelessWidget {
  final ReturnRequestModel request;

  const AdminReturnRequestDetailPage({super.key, required this.request});

  static PageRoute<void> route({
    required ReturnRequestModel request,
    required AdminReturnsCubit cubit,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: AdminReturnRequestDetailPage(request: request),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final statusInfo = _getStatusInfo(request.status, context);

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết Yêu cầu Đổi/Trả')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Thông tin chung'),
            _buildInfoRow('Mã yêu cầu:', request.id),
            _buildInfoRow('Mã đơn hàng:', '#${request.orderId.substring(0, 8).toUpperCase()}'),
            _buildInfoRow('Người yêu cầu:', request.userDisplayName),
            _buildInfoRow('Ngày tạo:', dateFormat.format(request.createdAt.toDate())),
            _buildInfoRow('Trạng thái:', statusInfo.$2, color: statusInfo.$1),
            const Divider(height: 32),

            _buildSectionTitle(context, 'Sản phẩm yêu cầu'),
            ...request.items.map((item) => _buildProductItem(item)).toList(),
            const Divider(height: 32),

            _buildSectionTitle(context, 'Lý do & Ghi chú'),
            _buildInfoRow('Lý do:', (request.items.first['reason'] ?? 'Không rõ')),
            if (request.userNotes.isNotEmpty)
              _buildInfoRow('Ghi chú của đại lý:', request.userNotes),
            if (request.adminNotes != null && request.adminNotes!.isNotEmpty)
              _buildInfoRow('Ghi chú của Admin:', request.adminNotes!),
            const Divider(height: 32),

            _buildSectionTitle(context, 'Hình ảnh bằng chứng'),
            _buildEvidenceImages(context, request.imageUrls),
          ],
        ),
      ),
      // --- THAY ĐỔI: Cập nhật logic hiển thị cho bottomNavigationBar ---
      bottomNavigationBar: Builder(
        builder: (context) {
          if (request.status == 'pending_approval') {
            return _ActionButtons(request: request);
          }
          if (request.status == 'approved') {
            return _MarkAsCompletedButton(request: request);
          }
          return const SizedBox.shrink();
        },
      ),
      // --- KẾT THÚC THAY ĐỔI ---
    );
  }

  // ... (các hàm build khác giữ nguyên)
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ', style: const TextStyle(color: Colors.grey)),
          Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color))),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(item['productName'] ?? 'Sản phẩm không tên'),
        subtitle: Text('Số lượng: ${item['quantity'] ?? 0}'),
      ),
    );
  }

  Widget _buildEvidenceImages(BuildContext context, List<String> imageUrls) {
    if (imageUrls.isEmpty) {
      return const Text('Không có hình ảnh nào được cung cấp.');
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: imageUrls.map((url) {
        return InkWell(
          onTap: () => _showImageDialog(context, url),
          child: Image.network(url, width: 80, height: 80, fit: BoxFit.cover),
        );
      }).toList(),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(imageUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _MarkAsCompletedButton extends StatelessWidget {
  final ReturnRequestModel request;
  const _MarkAsCompletedButton({required this.request});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16).copyWith(bottom: 16 + MediaQuery.of(context).padding.bottom),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('ĐÁNH DẤU HOÀN THÀNH'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            context.read<AdminReturnsCubit>().updateRequestStatus(
              requestId: request.id,
              newStatus: 'completed',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã cập nhật trạng thái thành "Hoàn thành"'), backgroundColor: Colors.green),
            );
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final ReturnRequestModel request;
  const _ActionButtons({required this.request});

  void _showRejectionDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lý do từ chối'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Nhập lý do từ chối...'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('HỦY'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isNotEmpty) {
                // Lấy cubit từ context của dialog
                context.read<AdminReturnsCubit>().updateRequestStatus(
                  requestId: request.id,
                  newStatus: 'rejected',
                  rejectionReason: reason,
                );
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              }
            },
            child: const Text('XÁC NHẬN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -2))]
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showRejectionDialog(context),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
              child: const Text('TỪ CHỐI'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                context.read<AdminReturnsCubit>().updateRequestStatus(
                  requestId: request.id,
                  newStatus: 'approved',
                );
                Navigator.of(context).pop();
              },
              child: const Text('DUYỆT YÊU CẦU'),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function để lấy màu và text cho status
(Color, String) _getStatusInfo(String status, BuildContext context) {
  switch (status) {
    case 'pending_approval': return (Colors.orange.shade700, 'Chờ duyệt');
    case 'approved': return (Colors.blue.shade700, 'Đã duyệt');
    case 'completed': return (Theme.of(context).colorScheme.primary, 'Hoàn thành');
    case 'rejected': return (Colors.red.shade700, 'Đã từ chối');
    default: return (Colors.grey.shade700, 'Không xác định');
  }
}