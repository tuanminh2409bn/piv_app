// lib/features/lucky_wheel/presentation/pages/spin_history_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/spin_history_model.dart';
import 'package:piv_app/features/lucky_wheel/presentation/bloc/history/spin_history_cubit.dart';

class SpinHistoryPage extends StatelessWidget {
  final bool isMyHistory; // True cho user, false cho admin

  const SpinHistoryPage({super.key, required this.isMyHistory});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<SpinHistoryCubit>()..watchHistory(isMyHistory),
      child: Scaffold(
        appBar: AppBar(
          title: Text(isMyHistory ? 'Lịch sử quay của bạn' : 'Toàn bộ Lịch sử'),
        ),
        body: BlocBuilder<SpinHistoryCubit, SpinHistoryState>(
          builder: (context, state) {
            if (state.status == SpinHistoryStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.history.isEmpty) {
              return const Center(child: Text('Không có dữ liệu lịch sử.'));
            }
            return ListView.builder(
              itemCount: state.history.length,
              itemBuilder: (context, index) {
                final history = state.history[index];
                return HistoryTile(history: history, showUserName: !isMyHistory);
              },
            );
          },
        ),
      ),
    );
  }
}

class HistoryTile extends StatelessWidget {
  final SpinHistoryModel history;
  final bool showUserName;

  const HistoryTile({
    super.key,
    required this.history,
    this.showUserName = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormatter = DateFormat('HH:mm - dd/MM/yyyy');
    return ListTile(
      leading: const Icon(Icons.star_border_purple500_sharp, color: Colors.amber),
      title: Text(
        showUserName
            ? '${history.userDisplayName} đã trúng "${history.rewardName}"'
            : 'Bạn đã trúng "${history.rewardName}"',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('Chiến dịch: ${history.campaignName}'),
      trailing: Text(
        timeFormatter.format(history.spunAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}