import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/data/models/discount_policy_model.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_users_cubit.dart';
import 'package:piv_app/features/admin/presentation/widgets/tier_table_editor.dart';

class AgentDiscountConfigPage extends StatefulWidget {
  final UserModel user;

  const AgentDiscountConfigPage({super.key, required this.user});

  static Route route({required UserModel user, required AdminUsersCubit cubit}) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: AgentDiscountConfigPage(user: user),
      ),
    );
  }

  @override
  State<AgentDiscountConfigPage> createState() => _AgentDiscountConfigPageState();
}

class _AgentDiscountConfigPageState extends State<AgentDiscountConfigPage> {
  late bool _enabled;
  late AgentPolicy _currentPolicy;

  @override
  void initState() {
    super.initState();
    _enabled = widget.user.customDiscountEnabled;
    if (widget.user.customDiscount != null && widget.user.customDiscount!['policy'] != null) {
      _currentPolicy = AgentPolicy.fromJson(widget.user.customDiscount!['policy']);
    } else {
      _currentPolicy = AgentPolicy(
        foliar: ProductTypePolicy(tiers: []),
        root: ProductTypePolicy(tiers: []),
      );
    }
  }

  void _saveConfig() {
    context.read<AdminUsersCubit>().updateUserDiscountConfig(
      userId: widget.user.id,
      enabled: _enabled,
      policy: _currentPolicy,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu cấu hình chiết khấu thành công!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cấu hình Chiết khấu Riêng'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfoCard(),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Kích hoạt cấu hình riêng', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Khi bật, đại lý sẽ dùng bảng giá này thay vì bảng giá chung.'),
              value: _enabled,
              onChanged: (val) => setState(() => _enabled = val),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 32),
            if (_enabled) ...[
              TierTableEditor(
                title: 'Phân Bón Lá',
                color: Colors.green.shade100,
                tiers: _currentPolicy.foliar.tiers,
                onChanged: (newTiers) {
                  setState(() {
                    _currentPolicy = AgentPolicy(
                      foliar: ProductTypePolicy(tiers: newTiers),
                      root: _currentPolicy.root,
                    );
                  });
                },
              ),
              const SizedBox(height: 24),
              TierTableEditor(
                title: 'Phân Bón Gốc',
                color: Colors.brown.shade100,
                tiers: _currentPolicy.root.tiers,
                onChanged: (newTiers) {
                  setState(() {
                    _currentPolicy = AgentPolicy(
                      foliar: _currentPolicy.foliar,
                      root: ProductTypePolicy(tiers: newTiers),
                    );
                  });
                },
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Đại lý sẽ sử dụng mức chiết khấu chung của hệ thống (dựa trên doanh số tích lũy).',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveConfig,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('LƯU CẤU HÌNH'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(widget.user.displayName?[0].toUpperCase() ?? 'A')),
        title: Text(widget.user.displayName ?? 'Chưa có tên', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(widget.user.email ?? 'Chưa có email'),
        trailing: Chip(
          label: Text(widget.user.status == 'active' ? 'Đã duyệt' : 'Chưa duyệt'),
          backgroundColor: widget.user.status == 'active' ? Colors.green.shade100 : Colors.orange.shade100,
          labelStyle: TextStyle(color: widget.user.status == 'active' ? Colors.green.shade800 : Colors.orange.shade800),
        ),
      ),
    );
  }
}
