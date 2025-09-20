// lib/features/sales_commitment/presentation/pages/sales_commitment_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/sales_commitment/presentation/bloc/agent/sales_commitment_agent_cubit.dart';
import 'package:piv_app/data/models/sales_commitment_model.dart';
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
    final user = (context.watch<AuthBloc>().state as AuthAuthenticated).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chương trình thưởng'),
      ),
      body: BlocBuilder<SalesCommitmentAgentCubit, SalesCommitmentAgentState>(
        builder: (context, state) {
          if (state.status == SalesCommitmentAgentStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == SalesCommitmentAgentStatus.error && state.errorMessage != null) {
            // Hiển thị lỗi ngay trên màn hình chính
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
              );
            });
          }

          if (user.activeRewardProgram == 'sales_target' && state.activeCommitment != null) {
            return ActiveCommitmentDashboard(commitment: state.activeCommitment!);
          } else {
            return ProgramSelectionView();
          }
        },
      ),
    );
  }
}

class ProgramSelectionView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
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
                        // ====================== KẾT NỐI NAVIGATION ======================
                        Navigator.of(context).push(
                            CreateCommitmentFormPage.route(context.read<SalesCommitmentAgentCubit>())
                        );
                        // ===============================================================
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

// ... (Class ActiveCommitmentDashboard giữ nguyên không đổi)
class ActiveCommitmentDashboard extends StatelessWidget {
  final SalesCommitmentModel commitment;
  const ActiveCommitmentDashboard({super.key, required this.commitment});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final progress = (commitment.currentAmount / commitment.targetAmount).clamp(0.0, 1.0);

    return Padding(
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