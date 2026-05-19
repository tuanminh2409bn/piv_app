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
  late TextEditingController _vatController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _policy = widget.initialPolicy;
    _vatController = TextEditingController(text: _policy.vatPercentage.toString());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _vatController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final double? vat = double.tryParse(_vatController.text);
    if (vat != null) {
      _policy = DiscountPolicyModel(
        agent1: _policy.agent1,
        agent2: _policy.agent2,
        agent1DueDays: _policy.agent1DueDays,
        agent2DueDays: _policy.agent2DueDays,
        agent1PromotionConfig: _policy.agent1PromotionConfig,
        agent2PromotionConfig: _policy.agent2PromotionConfig,
        vatPercentage: vat,
        globalAllowVoucherStacking: _policy.globalAllowVoucherStacking,
      );
    }
    context.read<AdminDiscountSettingsCubit>().updateSettings(_policy);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu cấu hình thành công!')));
  }

  void _updatePolicy(AgentPolicy updatedAgentPolicy, bool isAgent1) {
    setState(() {
      _policy = DiscountPolicyModel(
        agent1: isAgent1 ? updatedAgentPolicy : _policy.agent1,
        agent2: isAgent1 ? _policy.agent2 : updatedAgentPolicy,
        agent1DueDays: _policy.agent1DueDays,
        agent2DueDays: _policy.agent2DueDays,
        agent1PromotionConfig: _policy.agent1PromotionConfig,
        agent2PromotionConfig: _policy.agent2PromotionConfig,
        vatPercentage: _policy.vatPercentage,
        globalAllowVoucherStacking: _policy.globalAllowVoucherStacking,
      );
    });
  }

  void _updateDueDaysPolicy(AgentDueDaysPolicy updatedAgentDueDaysPolicy, bool isAgent1) {
    setState(() {
      _policy = DiscountPolicyModel(
        agent1: _policy.agent1,
        agent2: _policy.agent2,
        agent1DueDays: isAgent1 ? updatedAgentDueDaysPolicy : _policy.agent1DueDays,
        agent2DueDays: isAgent1 ? _policy.agent2DueDays : updatedAgentDueDaysPolicy,
        agent1PromotionConfig: _policy.agent1PromotionConfig,
        agent2PromotionConfig: _policy.agent2PromotionConfig,
        vatPercentage: _policy.vatPercentage,
        globalAllowVoucherStacking: _policy.globalAllowVoucherStacking,
      );
    });
  }

  void _updatePromotionPolicy(AgentPromotionConfig updatedPromotionConfig, bool isAgent1) {
    setState(() {
      _policy = DiscountPolicyModel(
        agent1: _policy.agent1,
        agent2: _policy.agent2,
        agent1DueDays: _policy.agent1DueDays,
        agent2DueDays: _policy.agent2DueDays,
        agent1PromotionConfig: isAgent1 ? updatedPromotionConfig : _policy.agent1PromotionConfig,
        agent2PromotionConfig: isAgent1 ? _policy.agent2PromotionConfig : updatedPromotionConfig,
        vatPercentage: _policy.vatPercentage,
        globalAllowVoucherStacking: _policy.globalAllowVoucherStacking,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    flex: 3,
                    child: Text('Thuế GTGT (VAT) %:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: _vatController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text('Cho phép cộng dồn Voucher & Chiết khấu:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Switch(
                    value: _policy.globalAllowVoucherStacking,
                    onChanged: (val) {
                      setState(() {
                        _policy = DiscountPolicyModel(
                          agent1: _policy.agent1,
                          agent2: _policy.agent2,
                          agent1DueDays: _policy.agent1DueDays,
                          agent2DueDays: _policy.agent2DueDays,
                          agent1PromotionConfig: _policy.agent1PromotionConfig,
                          agent2PromotionConfig: _policy.agent2PromotionConfig,
                          vatPercentage: _policy.vatPercentage,
                          globalAllowVoucherStacking: val,
                        );
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
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
                dueDaysPolicy: _policy.agent1DueDays,
                promotionConfig: _policy.agent1PromotionConfig,
                onChanged: (p) => _updatePolicy(p, true),
                onDueDaysChanged: (p) => _updateDueDaysPolicy(p, true),
                onPromotionConfigChanged: (p) => _updatePromotionPolicy(p, true),
              ),
              _AgentPolicyEditor(
                policy: _policy.agent2,
                dueDaysPolicy: _policy.agent2DueDays,
                promotionConfig: _policy.agent2PromotionConfig,
                onChanged: (p) => _updatePolicy(p, false),
                onDueDaysChanged: (p) => _updateDueDaysPolicy(p, false),
                onPromotionConfigChanged: (p) => _updatePromotionPolicy(p, false),
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
  final AgentDueDaysPolicy dueDaysPolicy;
  final AgentPromotionConfig promotionConfig;
  final ValueChanged<AgentPolicy> onChanged;
  final ValueChanged<AgentDueDaysPolicy> onDueDaysChanged;
  final ValueChanged<AgentPromotionConfig> onPromotionConfigChanged;

  const _AgentPolicyEditor({
    required this.policy,
    required this.dueDaysPolicy,
    required this.promotionConfig,
    required this.onChanged,
    required this.onDueDaysChanged,
    required this.onPromotionConfigChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hạn thanh toán mặc định (ngày)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: dueDaysPolicy.foliar.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Phân bón lá', border: OutlineInputBorder()),
                          onChanged: (val) => onDueDaysChanged(
                            AgentDueDaysPolicy(foliar: int.tryParse(val) ?? 30, root: dueDaysPolicy.root, mixed: dueDaysPolicy.mixed),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: dueDaysPolicy.root.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Phân bón gốc', border: OutlineInputBorder()),
                          onChanged: (val) => onDueDaysChanged(
                            AgentDueDaysPolicy(foliar: dueDaysPolicy.foliar, root: int.tryParse(val) ?? 30, mixed: dueDaysPolicy.mixed),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: dueDaysPolicy.mixed.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Hỗn hợp', border: OutlineInputBorder()),
                          onChanged: (val) => onDueDaysChanged(
                            AgentDueDaysPolicy(foliar: dueDaysPolicy.foliar, root: dueDaysPolicy.root, mixed: int.tryParse(val) ?? 30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quyền lợi khuyến mãi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SwitchListTile(
                    title: const Text('Cho phép nhận Chiết khấu Đại lý'),
                    value: promotionConfig.allowDiscount,
                    onChanged: (val) => onPromotionConfigChanged(
                      AgentPromotionConfig(
                        allowDiscount: val, 
                        allowVoucher: promotionConfig.allowVoucher,
                        allowPromotionDuringCommitment: promotionConfig.allowPromotionDuringCommitment,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Cho phép dùng Mã giảm giá (Voucher)'),
                    value: promotionConfig.allowVoucher,
                    onChanged: (val) => onPromotionConfigChanged(
                      AgentPromotionConfig(
                        allowDiscount: promotionConfig.allowDiscount, 
                        allowVoucher: val,
                        allowPromotionDuringCommitment: promotionConfig.allowPromotionDuringCommitment,
                      ),
                    ),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Cho phép dùng Khuyến mãi (Chiết khấu & Voucher) khi đang có Cam kết doanh số'),
                    value: promotionConfig.allowPromotionDuringCommitment,
                    onChanged: (val) => onPromotionConfigChanged(
                      AgentPromotionConfig(
                        allowDiscount: promotionConfig.allowDiscount, 
                        allowVoucher: promotionConfig.allowVoucher,
                        allowPromotionDuringCommitment: val,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
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
