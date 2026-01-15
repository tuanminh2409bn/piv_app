//lib/features/lucky_wheel/presentation/pages/lucky_wheel_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/data/models/lucky_wheel_campaign_model.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/lucky_wheel/presentation/bloc/lucky_wheel_cubit.dart';
import 'package:rxdart/rxdart.dart';
import 'package:piv_app/features/lucky_wheel/presentation/pages/spin_history_page.dart';
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:piv_app/features/lucky_wheel/presentation/pages/lucky_wheel_rules_page.dart';

class LuckyWheelPage extends StatelessWidget {
  const LuckyWheelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<LuckyWheelCubit>(),
      child: const LuckyWheelView(),
    );
  }
}

class LuckyWheelView extends StatefulWidget {
  const LuckyWheelView({super.key});

  @override
  State<LuckyWheelView> createState() => _LuckyWheelViewState();
}

class _LuckyWheelViewState extends State<LuckyWheelView> {
  final selected = BehaviorSubject<int>();
  RewardModel? _lastWinningReward;
  late final Stream<int> _spinCountStream;

  @override
  void initState() {
    super.initState();
    final userId = (context.read<AuthBloc>().state as AuthAuthenticated).user.id;
    _spinCountStream = sl<UserProfileRepository>().watchSpinCount(userId);
  }

  @override
  void dispose() {
    selected.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Để nền tràn lên cả AppBar
      appBar: AppBar(
        title: const Text('Vòng Quay May Mắn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(LuckyWheelRulesPage.route()),
            child: const Text('Thể lệ', style: TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'Lịch sử quay',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SpinHistoryPage(isMyHistory: true))),
          ),
        ],
      ),
      body: BlocConsumer<LuckyWheelCubit, LuckyWheelState>(
        listener: (context, state) {
          if (state.status == LuckyWheelStatus.won && state.winningReward != null) {
            setState(() => _lastWinningReward = state.winningReward);
            final winningIndex = state.activeCampaign!.rewards.indexWhere((r) => r.name == state.winningReward!.name);
            if (winningIndex != -1) selected.add(winningIndex);
          } else if (state.status == LuckyWheelStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(state.errorMessage!), backgroundColor: AppTheme.errorRed));
          } else if (state.status == LuckyWheelStatus.success && state.successMessage != null){
            ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(state.successMessage!), backgroundColor: AppTheme.secondaryGreen));
          }
        },
        builder: (context, state) {
          if (state.status == LuckyWheelStatus.loading || state.status == LuckyWheelStatus.initial) {
            return _buildLoadingBackground();
          }

          if (state.activeCampaign == null) {
            return _buildEmptyCampaignView();
          }

          final rewards = state.activeCampaign!.rewards;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1a237e), Color(0xFF0d47a1), Color(0xFF01579b)], // Deep Blue Luxury
              ),
            ),
            child: Stack(
              children: [
                // Starry/Confetti Background (Placeholder for simpler noise/stars)
                Positioned.fill(
                  child: CustomPaint(painter: _StarryBackgroundPainter()),
                ),
                
                Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 80), // Space for AppBar
                        
                        // Wheel Container
                        SizedBox(
                          height: 340,
                          width: 340,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Glow Effect behind wheel
                              Container(
                                width: 320,
                                height: 320,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.amber.withOpacity(0.6), blurRadius: 40, spreadRadius: 5),
                                  ],
                                ),
                              ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 2000.ms),

                              // The Wheel
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: FortuneWheel(
                                  selected: selected.stream,
                                  animateFirst: false,
                                  physics: CircularPanPhysics(
                                    duration: const Duration(seconds: 1),
                                    curve: Curves.decelerate,
                                  ),
                                  onFling: () {
                                    context.read<LuckyWheelCubit>().spinWheel();
                                  },
                                  styleStrategy: const AlternatingStyleStrategy(),
                                  indicators: const <FortuneIndicator>[
                                    FortuneIndicator(
                                      alignment: Alignment.topCenter,
                                      child: TriangleIndicator(color: AppTheme.accentGold),
                                    ),
                                  ],
                                  items: [
                                    for (var i = 0; i < rewards.length; i++)
                                      FortuneItem(
                                          child: RotatedBox(
                                            quarterTurns: 1, // Xoay text để dễ đọc hơn
                                            child: Padding(
                                              padding: const EdgeInsets.only(bottom: 40.0),
                                              child: Text(
                                                rewards[i].name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: i.isEven ? AppTheme.textDark : Colors.white,
                                                  fontSize: 12,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          style: FortuneItemStyle(
                                            color: i.isEven ? Colors.white : AppTheme.errorRed, // Đỏ - Trắng xen kẽ
                                            borderColor: AppTheme.accentGold,
                                            borderWidth: 2,
                                          )
                                      ),
                                  ],
                                  onAnimationEnd: () {
                                    if (_lastWinningReward != null) {
                                      _showWinDialog(context);
                                    }
                                  },
                                ),
                              ),
                              
                              // Center Button Decor
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const RadialGradient(colors: [Colors.white, Colors.grey]),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)],
                                  border: Border.all(color: AppTheme.accentGold, width: 4),
                                ),
                                child: const Center(child: Icon(Icons.star, color: AppTheme.accentGold)),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Spin Count & Button
                        StreamBuilder<int>(
                          stream: _spinCountStream,
                          builder: (context, snapshot) {
                            final spinCount = snapshot.data ?? 0;
                            return Column(
                              children: [
                                Text(
                                  'LƯỢT QUAY CÒN LẠI',
                                  style: TextStyle(color: Colors.white.withOpacity(0.7), letterSpacing: 2, fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$spinCount',
                                  style: const TextStyle(fontSize: 48, color: AppTheme.accentGold, fontWeight: FontWeight.w900),
                                ).animate(target: spinCount > 0 ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 300.ms, curve: Curves.easeInOut),
                                
                                const SizedBox(height: 32),
                                
                                SizedBox(
                                  width: 200,
                                  height: 60,
                                  child: ElevatedButton(
                                    onPressed: (state.status == LuckyWheelStatus.spinning || spinCount == 0)
                                        ? null
                                        : () => context.read<LuckyWheelCubit>().spinWheel(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accentGold,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      elevation: 10,
                                      shadowColor: AppTheme.accentGold.withOpacity(0.5),
                                    ),
                                    child: state.status == LuckyWheelStatus.spinning
                                        ? const CircularProgressIndicator(color: Colors.black)
                                        : const Text('QUAY NGAY', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  ),
                                ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(delay: 2000.ms, duration: 1500.ms, color: Colors.white.withOpacity(0.5)),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showWinDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accentGold, width: 4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, size: 60, color: AppTheme.accentGold)
                  .animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 16),
              const Text('CHÚC MỪNG!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
              const SizedBox(height: 16),
              const Text('Bạn đã trúng phần thưởng:', textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                _lastWinningReward!.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.read<LuckyWheelCubit>().acknowledgeReward();
                },
                child: const Text('NHẬN THƯỞNG'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBackground() {
    return Container(
      color: const Color(0xFF1a237e),
      child: const Center(child: CircularProgressIndicator(color: AppTheme.accentGold)),
    );
  }

  Widget _buildEmptyCampaignView() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Vòng Quay May Mắn')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sentiment_dissatisfied, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Chưa có chương trình nào',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Vui lòng quay lại sau để tham gia các chương trình khuyến mãi hấp dẫn!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarryBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.2);
    // Vẽ các đốm sao ngẫu nhiên (giả lập đơn giản)
    // Trong thực tế có thể dùng Random, nhưng để tối ưu hiệu năng trong CustomPainter nên hạn chế
    // Ở đây vẽ mẫu vài điểm cố định
    final offsets = [
      Offset(size.width * 0.1, size.height * 0.1),
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.2, size.height * 0.8),
      Offset(size.width * 0.9, size.height * 0.9),
    ];
    for (var offset in offsets) {
      canvas.drawCircle(offset, 2, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
