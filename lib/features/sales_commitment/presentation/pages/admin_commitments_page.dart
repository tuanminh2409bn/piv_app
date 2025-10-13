// lib/features/sales_commitment/presentation/pages/admin_commitments_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/sales_commitment_model.dart';
import 'package:piv_app/features/sales_commitment/presentation/bloc/admin/sales_commitment_admin_cubit.dart';

class AdminCommitmentsPage extends StatelessWidget {
  const AdminCommitmentsPage({super.key});

  // <<< THÊM MỚI: Phương thức route() để đóng gói BlocProvider >>>
  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (context) => sl<SalesCommitmentAdminCubit>()..watchAllCommitments(),
        child: const AdminCommitmentsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Widget này giờ chỉ cần gọi AdminCommitmentsView
    return const AdminCommitmentsView();
  }
}

class AdminCommitmentsView extends StatelessWidget {
  const AdminCommitmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModalRoute.of(context)?.canPop ?? false
          ? AppBar(
        title: const Text('Quản lý Cam kết'),
      )
          : null,
      body: BlocBuilder<SalesCommitmentAdminCubit, SalesCommitmentAdminState>(
        builder: (context, state) {
          if (state.status == SalesCommitmentAdminStatus.loading && state.commitments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == SalesCommitmentAdminStatus.error) {
            return Center(child: Text(state.errorMessage ?? 'Đã có lỗi xảy ra.'));
          }
          if (state.commitments.isEmpty) {
            return const Center(child: Text('Chưa có cam kết nào được tạo.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: state.commitments.length,
            itemBuilder: (context, index) {
              final commitment = state.commitments[index];
              return CommitmentCard(commitment: commitment);
            },
          );
        },
      ),
    );
  }
}

// Lớp CommitmentCard giữ nguyên như phiên bản đã sửa lỗi hiển thị trước đó
class CommitmentCard extends StatelessWidget {
  // ... (Toàn bộ nội dung của CommitmentCard giữ nguyên)
  final SalesCommitmentModel commitment;
  const CommitmentCard({super.key, required this.commitment});

  void _showSetDetailsDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController(text: commitment.commitmentDetails?.text);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Thiết lập Phần thưởng'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'VD: Tặng 1 chỉ vàng SJC 9999',
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
                if (controller.text.isNotEmpty) {
                  context.read<SalesCommitmentAdminCubit>().setCommitmentDetails(
                    commitmentId: commitment.id,
                    detailsText: controller.text,
                  );
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '');
    final progress = (commitment.currentAmount / commitment.targetAmount).clamp(0.0, 1.0);
    final bool isCompleted = commitment.status == 'completed';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        commitment.userDisplayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Mục tiêu: ${currencyFormatter.format(commitment.targetAmount)} đ',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Chip(
                    label: const Text('Hoàn thành'),
                    backgroundColor: Colors.green.shade100,
                    labelStyle: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
                    avatar: Icon(Icons.check_circle, color: Colors.green.shade800),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (!isCompleted) ...[
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Đã đạt: ${currencyFormatter.format(commitment.currentAmount)} đ'),
                  Text('${(progress * 100).toStringAsFixed(1)}%'),
                ],
              ),
            ] else ...[
              Text(
                  'Đã đạt: ${currencyFormatter.format(commitment.currentAmount)} đ',
                  style: const TextStyle(fontWeight: FontWeight.bold)
              ),
            ],

            const Divider(height: 24),
            _buildDetailsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    if (commitment.commitmentDetails == null) {
      return Center(
        child: OutlinedButton.icon(
          onPressed: () => _showSetDetailsDialog(context),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Thiết lập Phần thưởng'),
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cam kết phần thưởng:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.card_giftcard_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(commitment.commitmentDetails!.text),
                    const SizedBox(height: 4),
                    Text(
                      'Bởi: ${commitment.commitmentDetails!.setByUserName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                onPressed: () => _showSetDetailsDialog(context),
                tooltip: 'Chỉnh sửa',
              )
            ],
          ),
        ],
      );
    }
  }
}