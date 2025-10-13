// lib/features/admin/presentation/pages/admin_settings_page.dart

import 'dart:ui'; // <--- THÊM IMPORT NÀY
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_settings_cubit.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AdminSettingsCubit>()..loadSettings(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cài đặt'),
        ),
        // ====================== BẮT ĐẦU SỬA ĐỔI ======================
        body: Stack(
          children: [
            // Lớp 1: Nội dung gốc của trang
            const AdminSettingsView(),

            // Lớp 2: Lớp kính mờ
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
            ),

            // Lớp 3: Lớp thông báo
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Tính năng này tạm thời chưa được áp dụng',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        // ======================= KẾT THÚC SỬA ĐỔI =======================
      ),
    );
  }
}

// Nội dung của AdminSettingsView và các widget con được giữ nguyên không đổi
class AdminSettingsView extends StatelessWidget {
  const AdminSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminSettingsCubit, AdminSettingsState>(
      builder: (context, state) {
        if (state.status == AdminSettingsStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text('Cài đặt chung', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _CommissionRateCard(initialRate: state.commissionRate),
          ],
        );
      },
    );
  }
}

class _CommissionRateCard extends StatefulWidget {
  final double initialRate;
  const _CommissionRateCard({required this.initialRate});

  @override
  State<_CommissionRateCard> createState() => _CommissionRateCardState();
}

class _CommissionRateCardState extends State<_CommissionRateCard> {
  late TextEditingController _textController;
  late double _currentSliderValue;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _currentSliderValue = (widget.initialRate * 100).clamp(0, 100);
    _textController = TextEditingController(text: _currentSliderValue.toStringAsFixed(1));
  }

  @override
  void didUpdateWidget(covariant _CommissionRateCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRate != oldWidget.initialRate && !_hasChanges) {
      final newRate = (widget.initialRate * 100).clamp(0, 100).toDouble();
      setState(() {
        _currentSliderValue = newRate;
        _textController.text = newRate.toStringAsFixed(1);
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onSave() {
    context.read<AdminSettingsCubit>().saveCommissionRate(_textController.text.trim());
    setState(() => _hasChanges = false);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.percent_rounded, color: Theme.of(context).colorScheme.primary),
              title: const Text('Tỷ lệ hoa hồng', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Tỷ lệ hoa hồng chung cho Nhân viên Kinh doanh'),
            ),
            const Divider(),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${_currentSliderValue.toStringAsFixed(1)} %',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary
                ),
              ),
            ),
            Slider(
              value: _currentSliderValue,
              min: 0,
              max: 100,
              divisions: 200,
              label: _currentSliderValue.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _hasChanges = true;
                  _currentSliderValue = value;
                  _textController.text = value.toStringAsFixed(1);
                });
              },
            ),
            Row(
              children: [
                const Expanded(child: Text('Hoặc nhập chính xác:', style: TextStyle(fontSize: 14))),
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    controller: _textController,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        suffixText: '%',
                        contentPadding: EdgeInsets.symmetric(horizontal: 8)
                    ),
                    onChanged: (value) {
                      final parsedValue = double.tryParse(value);
                      if (parsedValue != null && parsedValue >= 0 && parsedValue <= 100) {
                        setState(() {
                          _hasChanges = true;
                          _currentSliderValue = parsedValue;
                        });
                      } else {
                        setState(() {
                          _hasChanges = true;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_hasChanges)
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: _onSave,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Lưu thay đổi'),
                ),
              )
          ],
        ),
      ),
    );
  }
}