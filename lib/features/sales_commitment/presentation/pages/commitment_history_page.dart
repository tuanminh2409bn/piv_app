import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/sales_commitment_model.dart';
import 'package:piv_app/features/sales_commitment/presentation/bloc/agent/sales_commitment_agent_cubit.dart';

class CommitmentHistoryPage extends StatelessWidget {
  final String? commitmentId;

  const CommitmentHistoryPage({super.key, this.commitmentId});

  static Route<void> route({String? commitmentId}) {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (context) => sl<SalesCommitmentAgentCubit>(),
        child: CommitmentHistoryPage(commitmentId: commitmentId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử Cam kết')),
      body: BlocBuilder<SalesCommitmentAgentCubit, SalesCommitmentAgentState>(
        builder: (context, state) {
           if (state.status == SalesCommitmentAgentStatus.loading && state.history.isEmpty) {
             return const Center(child: CircularProgressIndicator());
           }
           if (state.history.isEmpty) {
             return const Center(child: Text('Bạn chưa tham gia chương trình cam kết nào.'));
           }

           // Sắp xếp: Nếu có commitmentId, đưa nó lên đầu
           List<SalesCommitmentModel> displayedList = List.from(state.history);
           if (commitmentId != null) {
             final index = displayedList.indexWhere((element) => element.id == commitmentId);
             if (index != -1) {
               final item = displayedList.removeAt(index);
               displayedList.insert(0, item);
             }
           }

           return ListView.builder(
             itemCount: displayedList.length,
             padding: const EdgeInsets.all(16),
             itemBuilder: (context, index) {
               final commitment = displayedList[index];
               final isHighlighted = commitment.id == commitmentId;
               return _HistoryItem(commitment: commitment, isHighlighted: isHighlighted);
             },
           );
        },
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final SalesCommitmentModel commitment;
  final bool isHighlighted;

  const _HistoryItem({required this.commitment, this.isHighlighted = false});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormatter = DateFormat('dd/MM/yyyy');
    
    final bool isCompleted = commitment.status == 'completed';
    final bool isCancelled = commitment.status == 'cancelled';
    final bool isExpired = commitment.status == 'expired';
    final bool isPending = commitment.status == 'pending_approval';
    final bool isActive = commitment.status == 'active';

    Color statusColor = Colors.grey;
    String statusText = 'Không rõ';
    IconData statusIcon = Icons.help_outline;

    if (isCompleted) {
      statusColor = Colors.green;
      statusText = 'Hoàn thành';
      statusIcon = Icons.check_circle;
    } else if (isCancelled) {
      statusColor = Colors.red;
      statusText = 'Đã hủy';
      statusIcon = Icons.cancel;
    } else if (isExpired) {
      statusColor = Colors.grey;
      statusText = 'Hết hạn';
      statusIcon = Icons.timer_off;
    } else if (isPending) {
      statusColor = Colors.orange;
      statusText = 'Chờ duyệt';
      statusIcon = Icons.hourglass_top;
    } else if (isActive) {
      statusColor = Colors.blue;
      statusText = 'Đang chạy';
      statusIcon = Icons.run_circle;
    }

    return Container(
      decoration: isHighlighted 
        ? BoxDecoration(
            border: Border.all(color: Theme.of(context).primaryColor, width: 2),
            borderRadius: BorderRadius.circular(14), // Lớn hơn border radius của Card một chút
          )
        : null,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: isHighlighted ? 4 : 2,
        color: isHighlighted ? Colors.blue.shade50 : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isHighlighted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active, size: 16, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text('Thông báo mới', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   Expanded(
                     child: Text(
                       'Mục tiêu: ${currencyFormatter.format(commitment.targetAmount)}',
                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                     ),
                   ),
                   const SizedBox(width: 8),
                   Chip(
                     label: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 12)),
                     backgroundColor: statusColor,
                     avatar: Icon(statusIcon, color: Colors.white, size: 16),
                     padding: const EdgeInsets.symmetric(horizontal: 4),
                     visualDensity: VisualDensity.compact,
                   )
                ],
              ),
              const SizedBox(height: 8),
              Text('Thời gian: ${dateFormatter.format(commitment.startDate)} - ${dateFormatter.format(commitment.endDate)}'),
              const Divider(height: 24),
              
              if (isActive || isCompleted) ...[
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     const Text('Đã đạt:'),
                     Text(
                       currencyFormatter.format(commitment.currentAmount),
                       style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                     ),
                   ],
                 ),
              ],
    
              if (isCancelled) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Đã hủy bởi: ${commitment.cancelledByName ?? "N/A"}', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold)),
                      if (commitment.cancellationReason != null)
                        Text('Lý do: ${commitment.cancellationReason}', style: TextStyle(color: Colors.red.shade900)),
                    ],
                  ),
                )
              ],
    
               if (isCompleted && commitment.commitmentDetails != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Phần thưởng: ${commitment.commitmentDetails!.text}', style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ],
          ),
        ),
      ),
    );
  }
}
