import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/sales_commitment_model.dart';
import 'package:piv_app/features/sales_commitment/presentation/bloc/admin/sales_commitment_admin_cubit.dart';

class AdminCommitmentsPage extends StatelessWidget {
  const AdminCommitmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<SalesCommitmentAdminCubit>()..watchAllCommitments(),
      child: const AdminCommitmentsView(),
    );
  }
}

class AdminCommitmentsView extends StatelessWidget {
  const AdminCommitmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Cam kết'),
      ),
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

class CommitmentCard extends StatelessWidget {
  final SalesCommitmentModel commitment;
  const CommitmentCard({super.key, required this.commitment});

  void _showSetDetailsDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Thiết lập Phần thưởng'),
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              commitment.userDisplayName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Mục tiêu: ${currencyFormatter.format(commitment.targetAmount)} đ',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Đã đạt: ${currencyFormatter.format(commitment.currentAmount)} đ'),
                Text('${(progress * 100).toStringAsFixed(1)}%'),
              ],
            ),
            const Divider(height: 24),
            if (commitment.commitmentDetails == null)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _showSetDetailsDialog(context),
                  icon: const Icon(Icons.edit),
                  label: const Text('Thiết lập Phần thưởng'),
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primaryContainer),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cam kết:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(commitment.commitmentDetails!.text),
                  const SizedBox(height: 4),
                  Text(
                    'Bởi: ${commitment.commitmentDetails!.setByUserName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}