import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
  late TextEditingController _seasonalRateController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _policy = widget.initialPolicy;
    _vatController = TextEditingController(text: _policy.vatPercentage.toString());
    _seasonalRateController = TextEditingController(text: (_policy.seasonalDiscountRate * 100).toStringAsFixed(1));
    _startDate = _policy.seasonalDiscountStart;
    _endDate = _policy.seasonalDiscountEnd;
    _startDateController = TextEditingController(
      text: _startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : '',
    );
    _endDateController = TextEditingController(
      text: _endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : '',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _vatController.dispose();
    _seasonalRateController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final double? vat = double.tryParse(_vatController.text);
    final double? seasonalRate = double.tryParse(_seasonalRateController.text);
    if (vat != null && seasonalRate != null) {
      _policy = _policy.copyWith(
        vatPercentage: vat,
        seasonalDiscountRate: seasonalRate / 100,
        seasonalDiscountStart: _startDate,
        seasonalDiscountEnd: _endDate,
        clearSeasonalDiscountStart: _startDate == null,
        clearSeasonalDiscountEnd: _endDate == null,
      );
    }
    context.read<AdminDiscountSettingsCubit>().updateSettings(_policy);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu cấu hình thành công!')));
  }

  void _updatePolicy(AgentPolicy updatedAgentPolicy, bool isAgent1) {
    setState(() {
      _policy = isAgent1 
          ? _policy.copyWith(agent1: updatedAgentPolicy) 
          : _policy.copyWith(agent2: updatedAgentPolicy);
    });
  }

  void _updateDueDaysPolicy(AgentDueDaysPolicy updatedAgentDueDaysPolicy, bool isAgent1) {
    setState(() {
      _policy = isAgent1 
          ? _policy.copyWith(agent1DueDays: updatedAgentDueDaysPolicy) 
          : _policy.copyWith(agent2DueDays: updatedAgentDueDaysPolicy);
    });
  }

  void _updatePromotionPolicy(AgentPromotionConfig updatedPromotionConfig, bool isAgent1) {
    setState(() {
      _policy = isAgent1 
          ? _policy.copyWith(agent1PromotionConfig: updatedPromotionConfig) 
          : _policy.copyWith(agent2PromotionConfig: updatedPromotionConfig);
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
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text('Cho phép cộng dồn Voucher & Chiết khấu:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  Switch(
                    value: _policy.globalAllowVoucherStacking,
                    onChanged: (val) {
                      setState(() {
                        _policy = _policy.copyWith(globalAllowVoucherStacking: val);
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                color: Colors.green.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.green.shade100, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.campaign, color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              const Text(
                                'Khuyến mãi thời vụ',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                              ),
                            ],
                          ),
                          Switch(
                            value: _policy.seasonalDiscountEnabled,
                            activeColor: Colors.green.shade700,
                            onChanged: (val) {
                              setState(() {
                                _policy = _policy.copyWith(seasonalDiscountEnabled: val);
                              });
                            },
                          ),
                        ],
                      ),
                      if (_policy.seasonalDiscountEnabled) ...[
                        const Divider(height: 16),
                        Row(
                          children: [
                            const Expanded(
                              flex: 4,
                              child: Text('Tỷ lệ chiết khấu thời vụ (%):', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _seasonalRateController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _startDateController,
                                decoration: const InputDecoration(
                                  labelText: 'Ngày bắt đầu',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                readOnly: true,
                                onTap: () async {
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (pickedDate != null) {
                                    setState(() {
                                      _startDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, 0, 0, 0);
                                      _startDateController.text = DateFormat('dd/MM/yyyy').format(_startDate!);
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _endDateController,
                                decoration: const InputDecoration(
                                  labelText: 'Ngày kết thúc',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                readOnly: true,
                                onTap: () async {
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: _endDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (pickedDate != null) {
                                    setState(() {
                                      _endDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, 23, 59, 59);
                                      _endDateController.text = DateFormat('dd/MM/yyyy').format(_endDate!);
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
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
