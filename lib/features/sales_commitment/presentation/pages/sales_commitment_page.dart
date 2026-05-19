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
                } else if (state.activeCommitment!.status == 'proposed_to_agent') {
                  content = ProposedCommitmentView(commitment: state.activeCommitment!);
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
                      expandedHeight: Responsive.isDesktop(context) ? 120.0 : 80.0,
                      pinned: true,
                      backgroundColor: AppTheme.primaryGreen,
                      leading: const BackButton(color: Colors.white),
                      flexibleSpace: FlexibleSpaceBar(
                        centerTitle: true,
                        title: Text('Chương trình thưởng',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: Responsive.isDesktop(context) ? 20 : 16)),
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

class ProposedCommitmentView extends StatelessWidget {
  final SalesCommitmentModel commitment;
  
  const ProposedCommitmentView({super.key, required this.commitment});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.decimalPattern('vi_VN');
    final dateFormatter = DateFormat('dd/MM/yyyy');
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Icon(Icons.mark_email_unread_outlined, size: 80, color: AppTheme.primaryGreen).animate().scale(duration: 500.ms),
          const SizedBox(height: 24),
          Text(
            'Bạn có một đề xuất Cam kết',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
          ),
          const SizedBox(height: 8),
          Text(
            'Được gửi từ ${commitment.commitmentDetails?.setByUserName ?? 'Công ty'}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Mức cam kết:', '${currencyFormatter.format(commitment.targetAmount)} VNĐ', isHighlight: true),
                  const Divider(height: 24),
                  _buildDetailRow('Thời gian:', '${dateFormatter.format(commitment.startDate)} - ${dateFormatter.format(commitment.endDate)}'),
                  const Divider(height: 24),
                  const Text('Chi tiết quyền lợi & phần thưởng:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textGrey)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      commitment.commitmentDetails?.text ?? 'Không có chi tiết.',
                      style: const TextStyle(color: AppTheme.textDark, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.read<SalesCommitmentAgentCubit>().respondToCommitmentProposal(
                      commitmentId: commitment.id,
                      isAccepted: false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorRed,
                    side: const BorderSide(color: AppTheme.errorRed),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.read<SalesCommitmentAgentCubit>().respondToCommitmentProposal(
                      commitmentId: commitment.id,
                      isAccepted: true,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Đồng ý tham gia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? AppTheme.primaryGreen : AppTheme.textDark,
              fontSize: isHighlight ? 18 : 14,
            ),
          ),
        ),
      ],
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
      shadowColor: color.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isActive ? color : Colors.transparent, width: 2)),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(isDesktop ? 12 : 10),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: isDesktop ? 28 : 24),
                ),
                SizedBox(width: isDesktop ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: isDesktop ? 20 : 16, fontWeight: FontWeight.bold)),
                      if (isActive && !isDesktop) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                          child: const Text('Đang dùng', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ]
                    ],
                  ),
                ),
                if (isActive && isDesktop)
                  Chip(
                    label: const Text('Đang dùng'),
                    backgroundColor: color,
                    labelStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  )
              ],
            ),
            SizedBox(height: isDesktop ? 16 : 12),
            Text(description, style: TextStyle(color: Colors.grey.shade700, height: 1.6, fontSize: isDesktop ? 15 : 13)),
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
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
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
                  child: _buildProgressCircle(progress, percent, isDesktop),
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
                              Colors.blue,
                              isDesktop),
                          const SizedBox(width: 16),
                          _buildStatCard(
                              'Đã đạt',
                              currencyFormatter.format(commitment.currentAmount),
                              Icons.trending_up,
                              Colors.green,
                              isDesktop),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildRewardCard(commitment, isDesktop),
                    ],
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildProgressCircle(progress, percent, isDesktop),
                const SizedBox(height: 32),
                Row(
                  children: [
                    _buildStatCard(
                        'Mục tiêu',
                        currencyFormatter.format(commitment.targetAmount),
                        Icons.flag,
                        Colors.blue,
                        isDesktop),
                    const SizedBox(width: 12),
                    _buildStatCard(
                        'Đã đạt',
                        currencyFormatter.format(commitment.currentAmount),
                        Icons.trending_up,
                        Colors.green,
                        isDesktop),
                  ],
                ),
                const SizedBox(height: 24),
                _buildRewardCard(commitment, isDesktop),
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

  Widget _buildProgressCircle(double progress, String percent, bool isDesktop) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: isDesktop ? 200 : 160,
          height: isDesktop ? 200 : 160,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: isDesktop ? 15 : 12,
            backgroundColor: Colors.grey.shade200,
            color: AppTheme.primaryGreen,
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$percent%',
                style: TextStyle(
                    fontSize: isDesktop ? 40 : 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen)),
            Text('Đã hoàn thành',
                style: TextStyle(color: AppTheme.textGrey, fontSize: isDesktop ? 14 : 12)),
          ],
        ),
      ],
    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack);
  }

  Widget _buildRewardCard(SalesCommitmentModel commitment, bool isDesktop) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.amber.shade50,
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 20.0 : 16.0),
        child: Row(
          children: [
            Icon(Icons.emoji_events, size: isDesktop ? 48 : 36, color: Colors.amber),
            SizedBox(width: isDesktop ? 20 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PHẦN THƯỞNG DỰ KIẾN',
                      style: TextStyle(
                          fontSize: isDesktop ? 12 : 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                          letterSpacing: 1.1)),
                  const SizedBox(height: 6),
                  Text(
                    commitment.commitmentDetails?.text ?? 'Đang cập nhật...',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: isDesktop ? 18 : 14),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDesktop) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 20 : 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: isDesktop ? 24 : 20),
            SizedBox(height: isDesktop ? 12 : 8),
            Text(label,
                style: TextStyle(color: AppTheme.textGrey, fontSize: isDesktop ? 12 : 11)),
            const SizedBox(height: 4),
            Text(value,
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: isDesktop ? 18 : 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}