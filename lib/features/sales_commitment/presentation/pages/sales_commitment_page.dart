// lib/features/sales_commitment/presentation/pages/sales_commitment_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/sales_commitment/presentation/bloc/agent/sales_commitment_agent_cubit.dart';
import 'package:piv_app/data/models/sales_commitment_model.dart';
import 'package:piv_app/features/sales_commitment/presentation/pages/commitment_history_page.dart';
import 'create_commitment_form_page.dart';

class SalesCommitmentPage extends StatelessWidget {
  const SalesCommitmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<SalesCommitmentAgentCubit>(),
      child: const SalesCommitmentView(),
    );
  }
}

class SalesCommitmentView extends StatelessWidget {
  const SalesCommitmentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chương trình thưởng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Lịch sử cam kết',
            onPressed: () {
              Navigator.of(context).push(CommitmentHistoryPage.route());
            },
          )
        ],
      ),
      body: BlocBuilder<SalesCommitmentAgentCubit, SalesCommitmentAgentState>(
        builder: (context, state) {
          if (state.status == SalesCommitmentAgentStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == SalesCommitmentAgentStatus.error && state.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
              );
            });
          }

          if (state.activeCommitment != null) {
            if (state.activeCommitment!.status == 'pending_approval') {
              return const PendingApprovalView();
            }
            if (['active', 'pending_cancellation', 'completed'].contains(state.activeCommitment!.status)) {
               return ActiveCommitmentDashboard(commitment: state.activeCommitment!);
            }
          }
          
          return ProgramSelectionView();
        },
      ),
    );
  }
}

class PendingApprovalView extends StatelessWidget {
  const PendingApprovalView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_top, size: 80, color: Colors.orange.shade300),
              const SizedBox(height: 24),
              Text(
                'Đang chờ duyệt',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              const Text(
                'Yêu cầu đăng ký cam kết của bạn đang được công ty xem xét. Chúng tôi sẽ thông báo ngay khi cam kết được duyệt và bạn có thể bắt đầu tích lũy doanh số.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () {
                   context.read<SalesCommitmentAgentCubit>().close(); 
                   Navigator.of(context).pop();
                },
                child: const Text('Quay lại trang chủ'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ProgramSelectionView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Chọn chương trình của bạn', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chiết khấu Tức thời', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Bạn đang ở trong chương trình này. Bạn sẽ nhận được chiết khấu hoa hồng trực tiếp trên mỗi đơn hàng đủ điều kiện.'),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Chip(
                      label: Text('Đang áp dụng'),
                      backgroundColor: Colors.green,
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cam kết Doanh thu', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Từ bỏ chiết khấu tức thời để nhận phần thưởng lớn hơn khi đạt mục tiêu doanh số do bạn tự đặt ra trong một khoảng thời gian.'),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                            CreateCommitmentFormPage.route(context.read<SalesCommitmentAgentCubit>())
                        );
                      },
                      child: const Text('Đăng ký tham gia'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ActiveCommitmentDashboard extends StatelessWidget {
  final SalesCommitmentModel commitment;
  const ActiveCommitmentDashboard({super.key, required this.commitment});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final progress = (commitment.currentAmount / commitment.targetAmount).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cam kết của bạn', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mục tiêu: ${currencyFormatter.format(commitment.targetAmount)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thời gian: ${dateFormatter.format(commitment.startDate)} - ${dateFormatter.format(commitment.endDate)}',
                  ),
                  const SizedBox(height: 24),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đã đạt: ${currencyFormatter.format(commitment.currentAmount)}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Text('Phần thưởng cam kết:', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  commitment.commitmentDetails != null
                      ? Text(
                    commitment.commitmentDetails!.text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.normal),
                  )
                      : const Text(
                    'Chờ công ty xác nhận phần thưởng...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
