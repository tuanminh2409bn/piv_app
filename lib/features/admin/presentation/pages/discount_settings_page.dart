import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/admin/data/models/discount_policy_model.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_discount_settings_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_discount_settings_state.dart';
import 'package:piv_app/features/admin/presentation/widgets/tier_table_editor.dart';

class DiscountSettingsPage extends StatelessWidget {
  const DiscountSettingsPage({super.key});

  static Route route() {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (context) => sl<AdminDiscountSettingsCubit>()..loadSettings(),
        child: const DiscountSettingsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cấu hình Chiết khấu Chung')),
      body: BlocBuilder<AdminDiscountSettingsCubit, AdminDiscountSettingsState>(
        builder: (context, state) {
          if (state is AdminDiscountSettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminDiscountSettingsError) {
            return Center(child: Text('Lỗi: ${state.message}'));
          }
          if (state is AdminDiscountSettingsLoaded) {
            return _DiscountSettingsForm(initialPolicy: state.policy);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _DiscountSettingsForm extends StatefulWidget {
  final DiscountPolicyModel initialPolicy;

  const _DiscountSettingsForm({required this.initialPolicy});

  @override
  State<_DiscountSettingsForm> createState() => _DiscountSettingsFormState();
}

class _DiscountSettingsFormState extends State<_DiscountSettingsForm> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DiscountPolicyModel _policy;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _policy = widget.initialPolicy;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    context.read<AdminDiscountSettingsCubit>().updateSettings(_policy);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu cấu hình thành công!')));
  }

  void _updatePolicy(AgentPolicy updatedAgentPolicy, bool isAgent1) {
    setState(() {
      _policy = DiscountPolicyModel(
        agent1: isAgent1 ? updatedAgentPolicy : _policy.agent1,
        agent2: isAgent1 ? _policy.agent2 : updatedAgentPolicy,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Đại lý Cấp 1'),
            Tab(text: 'Đại lý Cấp 2'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _AgentPolicyEditor(
                policy: _policy.agent1,
                onChanged: (p) => _updatePolicy(p, true),
              ),
              _AgentPolicyEditor(
                policy: _policy.agent2,
                onChanged: (p) => _updatePolicy(p, false),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('LƯU CẤU HÌNH'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AgentPolicyEditor extends StatelessWidget {
  final AgentPolicy policy;
  final ValueChanged<AgentPolicy> onChanged;

  const _AgentPolicyEditor({required this.policy, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TierTableEditor(
            title: 'Phân Bón Lá',
            color: Colors.green.shade100,
            tiers: policy.foliar.tiers,
            onChanged: (newTiers) {
              onChanged(AgentPolicy(
                foliar: ProductTypePolicy(tiers: newTiers),
                root: policy.root,
              ));
            },
          ),
          const SizedBox(height: 24),
          TierTableEditor(
            title: 'Phân Bón Gốc',
            color: Colors.brown.shade100,
            tiers: policy.root.tiers,
            onChanged: (newTiers) {
              onChanged(AgentPolicy(
                foliar: policy.foliar,
                root: ProductTypePolicy(tiers: newTiers),
              ));
            },
          ),
        ],
      ),
    );
  }
}
