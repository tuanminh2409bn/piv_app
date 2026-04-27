// lib/features/sales_commitment/presentation/pages/sales_commitment_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/core/theme/nature_background_painter.dart';
import 'package:piv_app/features/sales_commitment/presentation/bloc/agent/sales_commitment_agent_cubit.dart';
import 'package:piv_app/data/models/sales_commitment_model.dart';
import 'package:piv_app/features/sales_commitment/presentation/pages/commitment_history_page.dart';
import 'package:piv_app/core/utils/responsive.dart';
import 'package:piv_app/common/widgets/responsive_wrapper.dart';
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
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          // Background Pattern
          Positioned.fill(
            child: CustomPaint(
              painter: NatureBackgroundPainter(
                color1: AppTheme.primaryGreen.withValues(alpha: 0.05),
                color2: AppTheme.secondaryGreen.withValues(alpha: 0.03),
                accent: AppTheme.accentGold.withValues(alpha: 0.1),
              ),
            ),
          ),

          BlocBuilder<SalesCommitmentAgentCubit, SalesCommitmentAgentState>(
            builder: (context, state) {
              if (state.status == SalesCommitmentAgentStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == SalesCommitmentAgentStatus.error && state.errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                      const SizedBox(height: 16),
                      Text(state.errorMessage!),
                    ],
                  ),
                );
              }

              Widget content;
              if (state.activeCommitment != null) {
                if (state.activeCommitment!.status == 'pending_approval') {
                  content = const PendingApprovalView();
                } else if (['active', 'pending_cancellation', 'completed'].contains(state.activeCommitment!.status)) {
                  content = ActiveCommitmentDashboard(commitment: state.activeCommitment!);
                } else {
                  content = ProgramSelectionView();
                }
              } else {
                content = ProgramSelectionView();
              }

              return CustomScrollView(
                slivers: [
                  _wrapConstrained(
                    context,
                    SliverAppBar(
                      expandedHeight: 120.0,
                      pinned: true,
                      backgroundColor: AppTheme.primaryGreen,
                      leading: const BackButton(color: Colors.white),
                      flexibleSpace: FlexibleSpaceBar(
                        centerTitle: true,
                        title: const Text('Chương trình thưởng',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        background: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryGreen,
                                AppTheme.secondaryGreen
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.history, color: Colors.white),
                          tooltip: 'Lịch sử cam kết',
                          onPressed: () => Navigator.of(context)
                              .push(CommitmentHistoryPage.route()),
                        )
                      ],
                    ),
                  ),
                  _wrapConstrained(context, SliverToBoxAdapter(child: content)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Hàm hỗ trợ bọc các thành phần cần giới hạn chiều rộng trên Web
  Widget _wrapConstrained(BuildContext context, Widget sliver) {
    if (!Responsive.isDesktop(context)) return sliver;
    final double screenWidth = MediaQuery.of(context).size.width;
    const double maxWidth = 900;
    if (screenWidth <= maxWidth) return sliver;

    final double padding = (screenWidth - maxWidth) / 2;
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      sliver: sliver,
    );
  }
}

class PendingApprovalView extends StatelessWidget {
  const PendingApprovalView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(Icons.hourglass_top, size: 100, color: Colors.orange.shade300).animate().scale(duration: 500.ms),
          const SizedBox(height: 24),
          Text(
            'Đang chờ duyệt',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
          ),
          const SizedBox(height: 16),
          const Text(
            'Yêu cầu đăng ký cam kết của bạn đang được công ty xem xét.\nChúng tôi sẽ thông báo ngay khi cam kết được duyệt.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppTheme.textGrey, height: 1.5),
          ),
          const SizedBox(height: 40),
          OutlinedButton(
            onPressed: () {
               Navigator.of(context).pop();
            },
            child: const Text('QUAY LẠI'),
          )
        ],
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
          const SizedBox(height: 16),
          Text('CHỌN CHƯƠNG TRÌNH', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textGrey, fontSize: 12, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          
          // Option 1: Instant Discount
          _buildProgramCard(
            context,
            title: 'Chiết khấu Tức thời',
            description: 'Nhận chiết khấu hoa hồng trực tiếp trên mỗi đơn hàng. Phù hợp nếu bạn muốn nhận tiền mặt ngay.',
            icon: Icons.payments_outlined,
            color: Colors.teal,
            isActive: true,
          ),
          
          const SizedBox(height: 16),
          
          // Option 2: Commitment
          _buildProgramCard(
            context,
            title: 'Cam kết Doanh thu',
            description: 'Đặt mục tiêu doanh số để nhận phần thưởng lớn hơn (Vàng, Xe, Du lịch...).',
            icon: Icons.emoji_events_outlined,
            color: Colors.amber.shade700,
            onTap: () {
              Navigator.of(context).push(CreateCommitmentFormPage.route(context.read<SalesCommitmentAgentCubit>()));
            },
            buttonText: 'ĐĂNG KÝ NGAY',
          ),
        ],
      ),
    );
  }

  Widget _buildProgramCard(BuildContext context, {required String title, required String description, required IconData icon, required Color color, bool isActive = false, VoidCallback? onTap, String? buttonText}) {
    final bool isDesktop = Responsive.isDesktop(context);

    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isActive ? color : Colors.transparent, width: 2)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                if (isActive)
                  Chip(
                    label: const Text('Đang dùng'),
                    backgroundColor: color,
                    labelStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  )
              ],
            ),
            const SizedBox(height: 16),
            Text(description, style: TextStyle(color: Colors.grey.shade700, height: 1.6, fontSize: 15)),
            if (buttonText != null) ...[
              const SizedBox(height: 24),
              Align(
                alignment: isDesktop ? Alignment.centerLeft : Alignment.center,
                child: SizedBox(
                  width: isDesktop ? 200 : double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}

class ActiveCommitmentDashboard extends StatelessWidget {
  final SalesCommitmentModel commitment;
  const ActiveCommitmentDashboard({super.key, required this.commitment});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final progress =
        (commitment.currentAmount / commitment.targetAmount).clamp(0.0, 1.0);
    final percent = (progress * 100).toStringAsFixed(1);
    final bool isDesktop = Responsive.isDesktop(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Layout linh hoạt cho Dashboard
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Phần trăm bên trái
                Expanded(
                  flex: 1,
                  child: _buildProgressCircle(progress, percent),
                ),
                const SizedBox(width: 48),
                // Thông số bên phải
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildStatCard(
                              'Mục tiêu',
                              currencyFormatter.format(commitment.targetAmount),
                              Icons.flag,
                              Colors.blue),
                          const SizedBox(width: 16),
                          _buildStatCard(
                              'Đã đạt',
                              currencyFormatter.format(commitment.currentAmount),
                              Icons.trending_up,
                              Colors.green),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildRewardCard(commitment),
                    ],
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildProgressCircle(progress, percent),
                const SizedBox(height: 32),
                Row(
                  children: [
                    _buildStatCard(
                        'Mục tiêu',
                        currencyFormatter.format(commitment.targetAmount),
                        Icons.flag,
                        Colors.blue),
                    const SizedBox(width: 16),
                    _buildStatCard(
                        'Đã đạt',
                        currencyFormatter.format(commitment.currentAmount),
                        Icons.trending_up,
                        Colors.green),
                  ],
                ),
                const SizedBox(height: 24),
                _buildRewardCard(commitment),
              ],
            ),

          const SizedBox(height: 32),
          Text(
            'Thời hạn: ${dateFormatter.format(commitment.startDate)} - ${dateFormatter.format(commitment.endDate)}',
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCircle(double progress, String percent) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 15,
            backgroundColor: Colors.grey.shade200,
            color: AppTheme.primaryGreen,
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$percent%',
                style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen)),
            const Text('Đã hoàn thành',
                style: TextStyle(color: AppTheme.textGrey)),
          ],
        ),
      ],
    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack);
  }

  Widget _buildRewardCard(SalesCommitmentModel commitment) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            const Icon(Icons.emoji_events, size: 48, color: Colors.amber),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PHẦN THƯỞNG DỰ KIẾN',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                          letterSpacing: 1.1)),
                  const SizedBox(height: 6),
                  Text(
                    commitment.commitmentDetails?.text ?? 'Đang cập nhật...',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}