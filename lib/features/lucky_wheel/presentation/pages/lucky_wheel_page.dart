//lib/features/lucky_wheel/presentation/pages/lucky_wheel_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:piv_app/core/di/injection_container.dart';
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
      appBar: AppBar(
        title: const Text('Vòng Quay May Mắn'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(LuckyWheelRulesPage.route());
            },
            child: const Text(
              'Thể lệ',
              style: TextStyle(color: Colors.black), // Hoặc màu phù hợp với theme của bạn
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Lịch sử quay',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SpinHistoryPage(isMyHistory: true),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<LuckyWheelCubit, LuckyWheelState>(
        listener: (context, state) {
          if (state.status == LuckyWheelStatus.won && state.winningReward != null) {
            setState(() {
              _lastWinningReward = state.winningReward;
            });
            final winningIndex = state.activeCampaign!.rewards.indexWhere(
                  (r) => r.name == state.winningReward!.name,
            );
            if (winningIndex != -1) {
              selected.add(winningIndex);
            }
          } else if (state.status == LuckyWheelStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
              );
          } else if (state.status == LuckyWheelStatus.success && state.successMessage != null){
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(state.successMessage!), backgroundColor: Colors.green),
              );
          }
        },
        builder: (context, state) {
          if (state.status == LuckyWheelStatus.loading || state.status == LuckyWheelStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.activeCampaign == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Hiện tại chưa có chương trình Vòng Quay May Mắn nào diễn ra. Vui lòng quay lại sau!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          }

          final rewards = state.activeCampaign!.rewards;

          return Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/lucky_wheel_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 95),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 300,
                        width: 300,
                        child: FortuneWheel(
                          selected: selected.stream,
                          animateFirst: false,
                          styleStrategy: const AlternatingStyleStrategy(),
                          indicators: const <FortuneIndicator>[
                            FortuneIndicator(
                              alignment: Alignment.topCenter,
                              child: TriangleIndicator(color: Colors.amber),
                            ),
                          ],
                          items: [
                            for (var i = 0; i < rewards.length; i++)
                              FortuneItem(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 8.0),
                                          child: Text(
                                            rewards[i].name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: i.isEven ? Colors.white : Colors.black,
                                              fontSize: 9,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (rewards[i].imageUrl != null && rewards[i].imageUrl!.isNotEmpty)
                                        Image.network(rewards[i].imageUrl!, width: 30, height: 30)
                                      else
                                        Icon(
                                          Icons.card_giftcard,
                                          size: 30,
                                          color: i.isEven ? Colors.white : Colors.black,
                                        ),
                                    ],
                                  ),
                                  style: FortuneItemStyle(
                                    color: i.isEven ? Colors.redAccent : Colors.white,
                                    borderColor: Colors.grey.shade400,
                                    borderWidth: 1,
                                  )
                              ),
                          ],
                          onAnimationEnd: () {
                            if (_lastWinningReward != null) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => AlertDialog(
                                  title: const Row(
                                    children: [
                                      Icon(Icons.star, color: Colors.amber),
                                      SizedBox(width: 8),
                                      Text('Chúc Mừng!'),
                                    ],
                                  ),
                                  content: Text('Bạn đã trúng phần thưởng:\n\n"${_lastWinningReward!.name}"'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                        context.read<LuckyWheelCubit>().acknowledgeReward();
                                      },
                                      child: const Text('Tuyệt vời!'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  StreamBuilder<int>(
                    stream: _spinCountStream,
                    builder: (context, snapshot) {
                      final spinCount = snapshot.data ?? 0;
                      return Column(
                        children: [
                          Text('Bạn còn: $spinCount lượt quay', style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: (state.status == LuckyWheelStatus.spinning || spinCount == 0)
                                ? null
                                : () {
                              context.read<LuckyWheelCubit>().spinWheel();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
                              textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              shape: const StadiumBorder(),
                            ),
                            child: state.status == LuckyWheelStatus.spinning
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('QUAY'),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}