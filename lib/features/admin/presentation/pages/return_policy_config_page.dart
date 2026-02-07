import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/return_policy_config_model.dart';
import 'package:piv_app/features/admin/domain/repositories/admin_settings_repository.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_return_settings_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_return_settings_state.dart';

class ReturnPolicyConfigPage extends StatelessWidget {
  const ReturnPolicyConfigPage({super.key});

  static Route route() {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => AdminReturnSettingsCubit(
          repository: sl<AdminSettingsRepository>(),
        )..loadPolicy(),
        child: const ReturnPolicyConfigPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cấu hình Đổi Trả'),
      ),
      body: BlocBuilder<AdminReturnSettingsCubit, AdminReturnSettingsState>(
        builder: (context, state) {
          if (state is AdminReturnSettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AdminReturnSettingsError) {
            return Center(child: Text('Lỗi: ${state.message}'));
          } else if (state is AdminReturnSettingsLoaded) {
            return _ReturnPolicyForm(initialPolicy: state.policy);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ReturnPolicyForm extends StatefulWidget {
  final ReturnPolicyConfigModel initialPolicy;

  const _ReturnPolicyForm({required this.initialPolicy});

  @override
  State<_ReturnPolicyForm> createState() => _ReturnPolicyFormState();
}

class _ReturnPolicyFormState extends State<_ReturnPolicyForm> {
  late int _maxReturnMonths;
  late List<ReturnPolicyTier> _tiers;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _maxReturnMonths = widget.initialPolicy.maxReturnMonths;
    _tiers = List.from(widget.initialPolicy.tiers);
    // Sort tiers by minMonths
    _tiers.sort((a, b) => a.minMonths.compareTo(b.minMonths));
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newPolicy = ReturnPolicyConfigModel(
        maxReturnMonths: _maxReturnMonths,
        tiers: _tiers,
      );
      context.read<AdminReturnSettingsCubit>().updatePolicy(newPolicy);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu cấu hình đổi trả thành công!')),
      );
    }
  }

  void _addTier() {
    setState(() {
      int nextMin = 0;
      if (_tiers.isNotEmpty) {
        nextMin = _tiers.last.maxMonths;
      }
      _tiers.add(ReturnPolicyTier(
        minMonths: nextMin,
        maxMonths: nextMin + 3,
        penaltyPerCrate: 0,
      ));
    });
  }

  void _removeTier(int index) {
    setState(() {
      _tiers.removeAt(index);
    });
  }

  void _updateTier(int index, ReturnPolicyTier newTier) {
    setState(() {
      _tiers[index] = newTier;
      // Sort again to keep order
      _tiers.sort((a, b) => a.minMonths.compareTo(b.minMonths));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGeneralSettings(),
            const SizedBox(height: 24),
            _buildTiersList(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
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

  Widget _buildGeneralSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cài đặt chung',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _maxReturnMonths.toString(),
              decoration: const InputDecoration(
                labelText: 'Thời hạn đổi trả tối đa (tháng)',
                helperText: 'Sau thời gian này, yêu cầu có thể bị từ chối.',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) return 'Vui lòng nhập số tháng';
                return null;
              },
              onSaved: (value) {
                _maxReturnMonths = int.tryParse(value!) ?? 24;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTiersList() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Các mốc phí phạt',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton.icon(
              onPressed: _addTier,
              icon: const Icon(Icons.add),
              label: const Text('Thêm mốc'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_tiers.isEmpty)
          const Text('Chưa có mốc nào. Hệ thống sẽ tính phí = 0.',
              style: TextStyle(color: Colors.grey)),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _tiers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _TierItem(
              tier: _tiers[index],
              onDelete: () => _removeTier(index),
              onChanged: (updatedTier) => _updateTier(index, updatedTier),
            );
          },
        ),
      ],
    );
  }
}

class _TierItem extends StatelessWidget {
  final ReturnPolicyTier tier;
  final VoidCallback onDelete;
  final ValueChanged<ReturnPolicyTier> onChanged;

  const _TierItem({
    required this.tier,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.decimalPattern('vi');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: tier.minMonths.toString(),
                  decoration: const InputDecoration(
                      labelText: 'Từ (tháng)', isDense: true),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (val) {
                    onChanged(ReturnPolicyTier(
                      minMonths: int.tryParse(val) ?? 0,
                      maxMonths: tier.maxMonths,
                      penaltyPerCrate: tier.penaltyPerCrate,
                    ));
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('-'),
              ),
              Expanded(
                child: TextFormField(
                  initialValue: tier.maxMonths.toString(),
                  decoration: const InputDecoration(
                      labelText: 'Đến (tháng)', isDense: true),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (val) {
                    onChanged(ReturnPolicyTier(
                      minMonths: tier.minMonths,
                      maxMonths: int.tryParse(val) ?? 0,
                      penaltyPerCrate: tier.penaltyPerCrate,
                    ));
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: currencyFormat.format(tier.penaltyPerCrate),
            decoration: const InputDecoration(
              labelText: 'Phí phạt (VND / đơn vị)',
              isDense: true,
              border: OutlineInputBorder(),
              suffixText: 'VNĐ',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
               FilteringTextInputFormatter.digitsOnly,
               _CurrencyInputFormatter(),
            ],
            onChanged: (val) {
              final cleanVal = val.replaceAll('.', '');
              onChanged(ReturnPolicyTier(
                minMonths: tier.minMonths,
                maxMonths: tier.maxMonths,
                penaltyPerCrate: double.tryParse(cleanVal) ?? 0,
              ));
            },
          ),
        ],
      ),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    String value = newValue.text.replaceAll('.', ''); // Remove old dots
    final formatter = NumberFormat.decimalPattern('vi');
    String newText = formatter.format(double.tryParse(value) ?? 0);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
