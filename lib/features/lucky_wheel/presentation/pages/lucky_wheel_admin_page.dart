// lib/features/lucky_wheel/presentation/pages/lucky_wheel_admin_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/lucky_wheel_campaign_model.dart';
import 'package:piv_app/data/models/spin_history_model.dart';
import 'package:piv_app/features/lucky_wheel/presentation/bloc/admin/lucky_wheel_admin_cubit.dart';
import 'package:piv_app/features/lucky_wheel/presentation/pages/spin_history_page.dart';
import 'package:piv_app/features/lucky_wheel/presentation/pages/campaign_form_page.dart';


class LuckyWheelAdminPage extends StatelessWidget {
  const LuckyWheelAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<LuckyWheelAdminCubit>()..watchCampaignsAndHistory(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Quản lý Vòng Quay'),
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.campaign), text: 'Chiến dịch'),
                Tab(icon: Icon(Icons.history), text: 'Lịch sử quay'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              CampaignsManagementView(),
              SpinHistoryPage(isMyHistory: false),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CampaignFormPage()),
              );
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

// --- VIEW CHO QUẢN LÝ CHIẾN DỊCH ---
class CampaignsManagementView extends StatelessWidget {
  const CampaignsManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LuckyWheelAdminCubit, LuckyWheelAdminState>(
      builder: (context, state) {
        if (state.status == LuckyWheelAdminStatus.loading && state.campaigns.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.campaigns.isEmpty) {
          return const Center(child: Text('Chưa có chiến dịch nào.'));
        }
        return ListView.builder(
          itemCount: state.campaigns.length,
          itemBuilder: (context, index) {
            final campaign = state.campaigns[index];
            return CampaignCard(campaign: campaign);
          },
        );
      },
    );
  }
}

class CampaignCard extends StatelessWidget {
  final LuckyWheelCampaignModel campaign;
  const CampaignCard({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd/MM/yyyy');
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(campaign.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Từ ${dateFormatter.format(campaign.startDate)} đến ${dateFormatter.format(campaign.endDate)}'),
        trailing: Chip(
          label: Text(campaign.isActive ? 'Đang chạy' : 'Đã tắt'),
          backgroundColor: campaign.isActive ? Colors.green : Colors.grey,
          labelStyle: const TextStyle(color: Colors.white),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CampaignFormPage(campaign: campaign),
            ),
          );
        },
      ),
    );
  }
}


// --- VIEW CHO LỊCH SỬ QUAY THƯỞNG ---
class SpinHistoryView extends StatelessWidget {
  const SpinHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LuckyWheelAdminCubit, LuckyWheelAdminState>(
      builder: (context, state) {
        if (state.status == LuckyWheelAdminStatus.loading && state.spinHistory.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.spinHistory.isEmpty) {
          return const Center(child: Text('Chưa có ai quay thưởng.'));
        }
        return ListView.builder(
          itemCount: state.spinHistory.length,
          itemBuilder: (context, index) {
            final history = state.spinHistory[index];
            return HistoryTile(history: history);
          },
        );
      },
    );
  }
}

class HistoryTile extends StatelessWidget {
  final SpinHistoryModel history;
  const HistoryTile({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final timeFormatter = DateFormat('HH:mm - dd/MM/yyyy');
    return ListTile(
      leading: const Icon(Icons.star, color: Colors.amber),
      title: Text('${history.userDisplayName} đã trúng "${history.rewardName}"'),
      subtitle: Text('Chiến dịch: ${history.campaignName}'),
      trailing: Text(
        timeFormatter.format(history.spunAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}