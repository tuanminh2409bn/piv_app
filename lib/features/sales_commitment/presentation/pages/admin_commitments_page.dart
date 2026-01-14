// lib/features/sales_commitment/presentation/pages/admin_commitments_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/sales_commitment_model.dart';
import 'package:piv_app/features/sales_commitment/presentation/bloc/admin/sales_commitment_admin_cubit.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';

class AdminCommitmentsPage extends StatelessWidget {
  final String? commitmentId;

  const AdminCommitmentsPage({super.key, this.commitmentId});

  static Route<void> route({String? commitmentId}) {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (context) => sl<SalesCommitmentAdminCubit>()..watchAllCommitments(),
        child: AdminCommitmentsPage(commitmentId: commitmentId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminCommitmentsView(highlightCommitmentId: commitmentId);
  }
}

class AdminCommitmentsView extends StatefulWidget {
  final String? highlightCommitmentId;

  const AdminCommitmentsView({super.key, this.highlightCommitmentId});

  @override
  State<AdminCommitmentsView> createState() => _AdminCommitmentsViewState();
}

class _AdminCommitmentsViewState extends State<AdminCommitmentsView> {
  String? _filterId;

  @override
  void initState() {
    super.initState();
    _filterId = widget.highlightCommitmentId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModalRoute.of(context)?.canPop ?? false
          ? AppBar(
              title: const Text('Quản lý Cam kết'),
              actions: [
                if (_filterId != null)
                  TextButton(
                    onPressed: () => setState(() => _filterId = null),
                    child: const Text('Xem tất cả', style: TextStyle(color: Colors.white)),
                  )
              ],
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
          
          List<SalesCommitmentModel> displayedCommitments = state.commitments;
          if (_filterId != null) {
            displayedCommitments = state.commitments.where((c) => c.id == _filterId).toList();
            if (displayedCommitments.isEmpty && state.status == SalesCommitmentAdminStatus.success) {
               // Nếu không tìm thấy ID (có thể đã bị xóa hoặc lỗi), hiện thông báo nhỏ
               return Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Text('Không tìm thấy cam kết yêu cầu.'),
                   TextButton(
                     onPressed: () => setState(() => _filterId = null),
                     child: const Text('Xem danh sách'),
                   )
                 ],
               );
            }
          }

          if (displayedCommitments.isEmpty) {
            return const Center(child: Text('Chưa có cam kết nào được tạo.'));
          }

          return Column(
            children: [
              if (_filterId != null)
                Container(
                  color: Colors.yellow.shade100,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Đang hiển thị kết quả lọc theo thông báo.', style: TextStyle(fontSize: 12))),
                      InkWell(
                        onTap: () => setState(() => _filterId = null),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Text('XÓA LỌC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                        ),
                      )
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: displayedCommitments.length,
                  itemBuilder: (context, index) {
                    final commitment = displayedCommitments[index];
                    return CommitmentCard(commitment: commitment);
                  },
                ),
              ),
            ],
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
    final TextEditingController controller = TextEditingController(text: commitment.commitmentDetails?.text);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Thiết lập Phần thưởng & Duyệt'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'VD: Tặng 1 chỉ vàng SJC 9999',
              border: OutlineInputBorder(),
              helperText: 'Nhập phần thưởng để kích hoạt cam kết này.',
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
              child: const Text('Xác nhận & Duyệt'),
            ),
          ],
        );
      },
    );
  }

  void _showCancelDialog(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Yêu cầu Hủy Cam kết'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bạn có chắc chắn muốn hủy chương trình cam kết này không?'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Lý do hủy',
                  hintText: 'Nhập lý do hủy...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Quay lại'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                if (reasonController.text.trim().isNotEmpty) {
                  context.read<SalesCommitmentAdminCubit>().requestCancel(
                    commitmentId: commitment.id,
                    reason: reasonController.text.trim(),
                  );
                  Navigator.pop(dialogContext);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập lý do hủy')),
                  );
                }
              },
              child: const Text('Xác nhận Hủy', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '');
    final progress = (commitment.currentAmount / (commitment.targetAmount == 0 ? 1 : commitment.targetAmount)).clamp(0.0, 1.0);
    
    final authState = context.read<AuthBloc>().state;
    final String userRole = (authState is AuthAuthenticated) ? authState.user.role : '';
    final bool isAdmin = userRole == 'admin';

    final bool isCompleted = commitment.status == 'completed';
    final bool isCancelled = commitment.status == 'cancelled';
    final bool isExpired = commitment.status == 'expired';
    final bool isPendingCancellation = commitment.status == 'pending_cancellation';
    final bool isPendingApproval = commitment.status == 'pending_approval';

    Color cardColor = Colors.white;
    if (isCancelled || isExpired) cardColor = Colors.grey.shade100;
    if (isPendingApproval) cardColor = Colors.blue.shade50;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: isCancelled || isExpired ? 0 : 2,
      color: cardColor,
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isCancelled || isExpired ? Colors.grey : null,
                        ),
                      ),
                      Text(
                        'Mục tiêu: ${currencyFormatter.format(commitment.targetAmount)} đ',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(isCompleted, isCancelled, isExpired, isPendingCancellation, isPendingApproval),
              ],
            ),
            const SizedBox(height: 16),

            if (!isCompleted && !isCancelled && !isExpired && !isPendingApproval) ...[
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
            ] else if (isCancelled) ...[
               Text(
                  'Đã hủy bởi: ${commitment.cancelledByName ?? commitment.cancelledBy ?? 'N/A'}',
                  style: const TextStyle(color: Colors.red)
              ),
              if (commitment.cancellationReason != null)
                 Text('Lý do: ${commitment.cancellationReason}', style: const TextStyle(fontStyle: FontStyle.italic)),
            ] else if (isPendingApproval) ...[
               const Text('Đang chờ thiết lập phần thưởng và duyệt.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey)),
            ] else ...[
              Text(
                  'Đã đạt: ${currencyFormatter.format(commitment.currentAmount)} đ',
                  style: const TextStyle(fontWeight: FontWeight.bold)
              ),
            ],

            const Divider(height: 24),
            
            // Details or Cancellation Request
            if (isPendingCancellation && commitment.cancellationRequest != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Yêu cầu hủy đang chờ duyệt', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Người yêu cầu: ${commitment.cancellationRequest!.requesterName}'),
                    Text('Lý do: ${commitment.cancellationRequest!.reason}'),
                    if (isAdmin) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => context.read<SalesCommitmentAdminCubit>().rejectCancel(commitmentId: commitment.id),
                            child: const Text('Từ chối'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => context.read<SalesCommitmentAdminCubit>().approveCancel(commitmentId: commitment.id),
                            child: const Text('Duyệt Hủy', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      )
                    ]
                  ],
                ),
              )
            ] else ...[
              _buildDetailsSection(context, isCancelled || isExpired, isPendingApproval),
            ],

            // Action Buttons (Only for active commitments)
            if (!isCancelled && !isExpired && !isCompleted && !isPendingCancellation && !isPendingApproval) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showCancelDialog(context),
                  icon: const Icon(Icons.cancel_presentation, color: Colors.red),
                  label: const Text('Hủy Cam kết', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isCompleted, bool isCancelled, bool isExpired, bool isPendingCancellation, bool isPendingApproval) {
    if (isCancelled) {
      return Chip(
        label: const Text('Đã hủy'),
        backgroundColor: Colors.red.shade100,
        labelStyle: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold),
        avatar: Icon(Icons.cancel, color: Colors.red.shade800),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      );
    }
    if (isExpired) {
      return Chip(
        label: const Text('Hết hạn'),
        backgroundColor: Colors.grey.shade300,
        labelStyle: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold),
        avatar: Icon(Icons.timer_off, color: Colors.grey.shade800),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      );
    }
    if (isCompleted) {
      return Chip(
        label: const Text('Hoàn thành'),
        backgroundColor: Colors.green.shade100,
        labelStyle: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
        avatar: Icon(Icons.check_circle, color: Colors.green.shade800),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      );
    }
    if (isPendingCancellation) {
      return Chip(
        label: const Text('Chờ hủy'),
        backgroundColor: Colors.orange.shade100,
        labelStyle: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold),
        avatar: Icon(Icons.pending, color: Colors.orange.shade800),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      );
    }
    if (isPendingApproval) {
      return Chip(
        label: const Text('Chờ duyệt'),
        backgroundColor: Colors.blue.shade100,
        labelStyle: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
        avatar: Icon(Icons.verified_user, color: Colors.blue.shade800),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      );
    }
    return const SizedBox.shrink(); 
  }

  Widget _buildDetailsSection(BuildContext context, bool isReadOnly, bool isPendingApproval) {
    if (commitment.commitmentDetails == null) {
      if (isReadOnly) return const SizedBox.shrink();
      
      if (isPendingApproval) {
          return Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
              onPressed: () => _showSetDetailsDialog(context),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Duyệt & Thiết lập thưởng'),
            ),
          );
      }

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
              if (!isReadOnly)
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