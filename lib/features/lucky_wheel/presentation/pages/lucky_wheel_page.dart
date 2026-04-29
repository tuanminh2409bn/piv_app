//lib/features/lucky_wheel/presentation/pages/lucky_wheel_page.dart

import 'dart:async';
import 'dart:math' as math;
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
import 'package:piv_app/common/widgets/responsive_wrapper.dart';
import 'package:piv_app/core/utils/responsive.dart';
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
    // Lấy kích thước màn hình để xử lý responsive
    final size = MediaQuery.of(context).size;
    final bool isDesktop = Responsive.isDesktop(context);
    final double wheelSize = isDesktop 
        ? math.min(size.height * 0.6, 500.0) // Lớn hơn trên Desktop
        : math.min(size.width * 0.85, 300.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Vòng Quay May Mắn',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            tooltip: 'Thể lệ',
            onPressed: () => Navigator.of(context).push(LuckyWheelRulesPage.route()),
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'Lịch sử quay',
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SpinHistoryPage(isMyHistory: true))),
          ),
        ],
      ),
      body: BlocConsumer<LuckyWheelCubit, LuckyWheelState>(
        listener: (context, state) {
          if (state.status == LuckyWheelStatus.won && state.winningReward != null) {
            setState(() => _lastWinningReward = state.winningReward);
            final winningIndex =
                state.activeCampaign!.rewards.indexWhere((r) => r.name == state.winningReward!.name);
            if (winningIndex != -1) selected.add(winningIndex);
          } else if (state.status == LuckyWheelStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                  content: Text(state.errorMessage!), backgroundColor: AppTheme.errorRed));
          } else if (state.status == LuckyWheelStatus.success && state.successMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                  content: Text(state.successMessage!), backgroundColor: AppTheme.secondaryGreen));
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

          return Stack(
            children: [
              // 1. Nền Luxury Gradient & Họa tiết
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.2), // Tâm sáng hơi dịch lên trên chỗ vòng quay
                      radius: 1.3,
                      colors: [
                        Color(0xFF1565C0), // Blue 800 (Sáng ở tâm)
                        Color(0xFF0D47A1), // Blue 900
                        Color(0xFF000000), // Đen ở viền (Vignette)
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: CustomPaint(painter: _LuxuryBackgroundPainter()),
                ),
              ),

              // 2. Nội dung chính (Responsive)
              Center(
                child: ResponsiveWrapper(
                  maxWidth: 1000,
                  backgroundColor: Colors.transparent,
                  showShadow: false,
                  child: SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Spacer(flex: 2),
                          
                          // --- WHEEL SECTION ---
                          SizedBox(
                            height: wheelSize + 20, // Cộng thêm padding cho glow
                            width: wheelSize + 20,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Glow Effect (Hào quang sau vòng quay)
                                Container(
                                  width: wheelSize,
                                  height: wheelSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.amber.withOpacity(0.4),
                                          blurRadius: 50,
                                          spreadRadius: 10),
                                      BoxShadow(
                                          color: Colors.blue.withOpacity(0.5),
                                          blurRadius: 30,
                                          spreadRadius: 5),
                                    ],
                                  ),
                                ).animate(onPlay: (c) => c.repeat(reverse: true))
                                 .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.05, 1.05), duration: 2.seconds),

                                // Vòng quay chính
                                SizedBox(
                                  width: wheelSize,
                                  height: wheelSize,
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
                                              quarterTurns: 1,
                                              child: Padding(
                                                padding: EdgeInsets.only(bottom: wheelSize * 0.15), // Padding động theo size
                                                child: Text(
                                                  rewards[i].name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: i.isEven ? AppTheme.textDark : Colors.white,
                                                    fontSize: wheelSize * 0.04, // Font size động
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            style: FortuneItemStyle(
                                              color: i.isEven ? Colors.white : const Color(0xFFB71C1C), // Đỏ đậm sang trọng
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

                                // Nút tâm (Center Decor)
                                Container(
                                  width: wheelSize * 0.18, // 18% kích thước vòng quay
                                  height: wheelSize * 0.18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const RadialGradient(colors: [Colors.white, Color(0xFFCFD8DC)]),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))
                                    ],
                                    border: Border.all(color: AppTheme.accentGold, width: 3),
                                  ),
                                  child: Center(
                                    child: Icon(Icons.star, color: AppTheme.accentGold, size: wheelSize * 0.08),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const Spacer(flex: 1),

                          // --- INFO & BUTTON SECTION ---
                          StreamBuilder<int>(
                            stream: _spinCountStream,
                            builder: (context, snapshot) {
                              final spinCount = snapshot.data ?? 0;
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    child: Text(
                                      'LƯỢT QUAY CÒN LẠI',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        letterSpacing: 1.5,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '$spinCount',
                                    style: const TextStyle(
                                      fontSize: 56,
                                      color: AppTheme.accentGold,
                                      fontWeight: FontWeight.w900,
                                      shadows: [
                                        Shadow(color: Colors.orange, blurRadius: 20),
                                      ],
                                    ),
                                  ).animate(target: spinCount > 0 ? 1 : 0)
                                   .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 300.ms, curve: Curves.easeInOut),

                                  const SizedBox(height: 24),

                                  // Button "QUAY NGAY"
                                  GestureDetector(
                                    onTap: (state.status == LuckyWheelStatus.spinning || spinCount == 0)
                                        ? null
                                        : () => context.read<LuckyWheelCubit>().spinWheel(),
                                    child: Container(
                                      width: 220,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        gradient: (state.status == LuckyWheelStatus.spinning || spinCount == 0)
                                          ? LinearGradient(colors: [Colors.grey, Colors.grey.shade700])
                                          : const LinearGradient(
                                              colors: [Color(0xFFFFD700), Color(0xFFFFA000)], // Gold Gradient
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          if (state.status != LuckyWheelStatus.spinning && spinCount > 0)
                                            BoxShadow(
                                              color: AppTheme.accentGold.withOpacity(0.6),
                                              blurRadius: 15,
                                              offset: const Offset(0, 4),
                                            ),
                                        ],
                                      ),
                                      child: Center(
                                        child: state.status == LuckyWheelStatus.spinning
                                            ? const SizedBox(
                                                width: 24, height: 24,
                                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                                            : const Text(
                                                'QUAY NGAY',
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                      ),
                                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                                     .shimmer(delay: 2000.ms, duration: 1500.ms, color: Colors.white.withOpacity(0.6)),
                                  ),
                                ],
                              );
                            },
                          ),
                          const Spacer(flex: 2),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
            ],
          );
        },
      ),
    );
  }

  void _showWinDialog(BuildContext context) {
    final isNoPrize = _lastWinningReward!.name.toLowerCase().contains('không trúng');
    final bool isDesktop = Responsive.isDesktop(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: isDesktop ? 450 : null, // Giới hạn chiều rộng Dialog trên Web
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isNoPrize ? Colors.grey : AppTheme.accentGold, width: 4),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isNoPrize ? Icons.sentiment_dissatisfied : Icons.emoji_events,
                size: 70,
                color: isNoPrize ? Colors.grey : AppTheme.accentGold,
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut).shimmer(),
              const SizedBox(height: 16),
              Text(
                isNoPrize ? 'RẤT TIẾC!' : 'CHÚC MỪNG!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isNoPrize ? AppTheme.textGrey : AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isNoPrize
                    ? 'Rất tiếc bạn đã không trúng phần thưởng nào.'
                    : 'Bạn đã trúng phần thưởng:',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              if (isNoPrize)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Chúc bạn may mắn lần sau nhé!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppTheme.textGrey),
                  ),
                )
              else ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _lastWinningReward!.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isNoPrize ? AppTheme.errorRed : AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.read<LuckyWheelCubit>().acknowledgeReward();
                  },
                  child: Text(
                    isNoPrize ? 'ĐÓNG' : 'NHẬN THƯỞNG',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [Color(0xFF0D47A1), Color(0xFF000000)],
        ),
      ),
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

// --- CUSTOM PAINTERS FOR LUXURY EFFECT ---

class _LuxuryBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Vẽ các vòng tròn đồng tâm mờ ảo (Halo Effect)
    final paintHalo = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height * 0.4); // Tâm hơi dịch lên
    for (double r = 50; r < size.height; r += 40) {
      canvas.drawCircle(center, r, paintHalo);
    }

    // 2. Vẽ các đốm sáng lấp lánh (Bokeh/Gold Dust)
    final paintStar = Paint()..color = const Color(0xFFFFD700).withOpacity(0.2); // Vàng gold mờ
    final random = math.Random(42); // Seed cố định để không bị nháy khi repaint
    
    for (int i = 0; i < 40; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 3;
      canvas.drawCircle(Offset(dx, dy), radius, paintStar);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}