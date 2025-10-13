import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/voucher_with_details.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_vouchers_cubit.dart';
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';

class AdminVouchersPage extends StatelessWidget {
  const AdminVouchersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AdminVouchersCubit>()..fetchPendingVouchers(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Duyệt Voucher'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Chờ duyệt Tạo/Sửa'),
                Tab(text: 'Chờ duyệt Xóa'),
              ],
            ),
          ),
          body: const AdminVouchersView(),
        ),
      ),
    );
  }
}

class AdminVouchersView extends StatelessWidget {
  const AdminVouchersView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminVouchersCubit, AdminVouchersState>(
      builder: (context, state) {
        if (state.status == AdminVoucherStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == AdminVoucherStatus.error) {
          return Center(child: Text(state.errorMessage ?? 'Lỗi tải dữ liệu'));
        }

        return TabBarView(
          children: [
            _buildVoucherList(
              context,
              vouchers: state.pendingCreationVouchers,
              emptyMessage: 'Không có yêu cầu tạo/sửa voucher nào.',
              isDeletionRequest: false,
            ),
            _buildVoucherList(
              context,
              vouchers: state.pendingDeletionVouchers,
              emptyMessage: 'Không có yêu cầu xóa voucher nào.',
              isDeletionRequest: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildVoucherList(
      BuildContext context, {
        required List<VoucherWithDetails> vouchers,
        required String emptyMessage,
        bool isDeletionRequest = false,
      }) {
    if (vouchers.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: vouchers.length,
      itemBuilder: (context, index) {
        final item = vouchers[index];
        final voucher = item.voucher;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(voucher.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(voucher.description),
                const Divider(height: 20),
                Text('Người tạo: ${item.createdByName}'),
                Text('Ngày hết hạn: ${DateFormat('dd/MM/yyyy').format(voucher.expiresAt.toDate())}'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: const Text('TỪ CHỐI', style: TextStyle(color: Colors.red)),
                      onPressed: () => _showReviewDialog(context, voucher, 'reject', isDeletionRequest),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      child: Text(isDeletionRequest ? 'DUYỆT XÓA' : 'DUYỆT'),
                      onPressed: () => _showReviewDialog(context, voucher, 'approve', isDeletionRequest),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReviewDialog(BuildContext context, VoucherModel voucher, String decision, bool isDeletionRequest) {
    final notesController = TextEditingController();
    final cubit = context.read<AdminVouchersCubit>();
    String title = decision == 'approve' ? (isDeletionRequest ? 'Duyệt Xóa Voucher' : 'Duyệt Voucher') : 'Từ chối Voucher';
    String content = 'Bạn có chắc chắn muốn ${decision == 'approve' ? (isDeletionRequest ? 'xóa' : 'phê duyệt') : 'từ chối'} voucher "${voucher.id}"?';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(content),
            if (decision == 'reject') ...[
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Lý do từ chối (tùy chọn)'),
              ),
            ]
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('HỦY')),
          ElevatedButton(
            child: const Text('XÁC NHẬN'),
            onPressed: () {
              cubit.reviewVoucher(
                voucher: voucher,
                decision: decision,
                notes: notesController.text.trim(),
              );
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      ),
    );
  }
}