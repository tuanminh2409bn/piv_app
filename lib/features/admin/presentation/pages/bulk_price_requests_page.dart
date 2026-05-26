// lib/features/admin/presentation/pages/bulk_price_requests_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/data/models/bulk_price_request_model.dart';
import 'package:piv_app/features/admin/presentation/bloc/bulk_price_requests_cubit.dart';

class BulkPriceRequestsPage extends StatelessWidget {
  const BulkPriceRequestsPage({super.key});

  static PageRoute route() {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (context) => sl<BulkPriceRequestsCubit>()..watchPendingRequests(),
        child: const BulkPriceRequestsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu cầu điều chỉnh giá'),
      ),
      body: BlocConsumer<BulkPriceRequestsCubit, BulkPriceRequestsState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.successMessage!), backgroundColor: Colors.green),
            );
          }
          if (state.errorMessage != null && state.status == BulkPriceRequestsStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state.status == BulkPriceRequestsStatus.loading && state.requests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Không có yêu cầu nào đang chờ duyệt',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => context.read<BulkPriceRequestsCubit>().watchPendingRequests(),
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + MediaQuery.of(context).padding.bottom),
              itemCount: state.requests.length,
              itemBuilder: (context, index) {
                return _BulkRequestCard(request: state.requests[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _BulkRequestCard extends StatelessWidget {
  final BulkPriceRequestModel request;
  const _BulkRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isIncrease = request.adjustmentValue > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isIncrease ? Colors.green.shade100 : Colors.red.shade100,
                  radius: 18,
                  child: Icon(
                    isIncrease ? Icons.trending_up : Icons.trending_down,
                    color: isIncrease ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${request.displayDirection} ${request.displayAdjustment}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isIncrease ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                      Text(
                        request.displayPriceType,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Chờ duyệt',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Details
            _buildDetailRow(Icons.person_outline, 'Người gửi:', '${request.requesterName} (${request.requesterRole == 'accountant' ? 'Kế toán' : 'NVKD'})'),
            _buildDetailRow(Icons.inventory_2_outlined, 'Sản phẩm:', request.displayProductTarget),
            _buildDetailRow(Icons.people_outline, 'Đại lý:', request.displayAgentTarget),
            if (request.excludedAgentIds.isNotEmpty)
              _buildDetailRow(Icons.person_off_outlined, 'Loại trừ:', '${request.excludedAgentNames.isNotEmpty ? request.excludedAgentNames.join(", ") : "${request.excludedAgentIds.length} đại lý"}'),
            _buildDetailRow(Icons.access_time, 'Ngày gửi:', dateFormat.format(request.createdAt)),

            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Từ chối'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => _showRejectDialog(context),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Duyệt & Áp dụng'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _showApproveDialog(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận duyệt'),
        content: Text(
          'Bạn xác nhận duyệt yêu cầu ${request.displayDirection.toLowerCase()} ${request.displayAdjustment} '
          '${request.displayPriceType.toLowerCase()} cho ${request.displayAgentTarget.toLowerCase()}?\n\n'
          'Hành động này sẽ áp dụng ngay lập tức.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<BulkPriceRequestsCubit>().approveRequest(request);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
            child: const Text('Duyệt & Áp dụng'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Từ chối yêu cầu'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Lý do từ chối...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do từ chối')),
                );
                return;
              }
              Navigator.pop(dialogContext);
              context.read<BulkPriceRequestsCubit>().rejectRequest(
                request.id,
                reasonController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }
}
