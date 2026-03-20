// lib/features/admin/presentation/pages/price_adjustment_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/admin/presentation/bloc/price_adjustment_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/price_adjustment_state.dart';

class PriceAdjustmentPage extends StatefulWidget {
  const PriceAdjustmentPage({super.key});

  static PageRoute route() {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (context) => sl<PriceAdjustmentCubit>(),
        child: const PriceAdjustmentPage(),
      ),
    );
  }

  @override
  State<PriceAdjustmentPage> createState() => _PriceAdjustmentPageState();
}

class _PriceAdjustmentPageState extends State<PriceAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _formatter = NumberFormat.decimalPattern('vi_VN');
  
  String _adjustmentType = 'percentage'; // 'percentage' or 'amount'
  String _productTarget = 'all'; // 'all', 'foliar_fertilizer', 'root_fertilizer'
  String _agentTarget = 'all'; // 'all', 'agent_1', 'agent_2'
  bool _isIncrease = true;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _onAdjustPressed() {
    if (!_formKey.currentState!.validate()) return;

    // Lưu Cubit vào biến trước khi mở Dialog
    final cubit = context.read<PriceAdjustmentCubit>();

    // Loại bỏ dấu chấm trước khi parse sang double
    final String cleanValue = _valueController.text.replaceAll('.', '');
    final double rawValue = double.tryParse(cleanValue) ?? 0;
    
    if (rawValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập giá trị lớn hơn 0')),
      );
      return;
    }

    final double adjustmentValue = _isIncrease ? rawValue : -rawValue;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận điều chỉnh giá'),
        content: Text(
          'Bạn có chắc chắn muốn ${_isIncrease ? "NÂNG" : "HẠ"} giá '
          '${_adjustmentType == "percentage" ? "$rawValue%" : "${_formatter.format(rawValue)} VND"} '
          'cho ${_getProductTargetText()} của ${_getAgentTargetText()} không?\n\n'
          'Hành động này sẽ cập nhật hàng loạt và gửi thông báo cho các bên liên quan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              cubit.adjustPrices(
                adjustmentType: _adjustmentType,
                adjustmentValue: adjustmentValue,
                productTarget: _productTarget,
                agentTarget: _agentTarget,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  String _getProductTargetText() {
    switch (_productTarget) {
      case 'all': return 'Toàn bộ mặt hàng';
      case 'foliar_fertilizer': return 'Phân bón lá';
      case 'root_fertilizer': return 'Phân bón gốc';
      default: return '';
    }
  }

  String _getAgentTargetText() {
    switch (_agentTarget) {
      case 'all': return 'Tất cả đại lý';
      case 'agent_1': return 'Đại lý cấp 1';
      case 'agent_2': return 'Đại lý cấp 2';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điều chỉnh giá hàng loạt'),
      ),
      body: BlocConsumer<PriceAdjustmentCubit, PriceAdjustmentState>(
        listener: (context, state) {
          if (state.status == PriceAdjustmentStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.successMessage ?? 'Thành công'), backgroundColor: Colors.green),
            );
            _valueController.clear();
          } else if (state.status == PriceAdjustmentStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Có lỗi xảy ra'), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state.status == PriceAdjustmentStatus.loading;

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16.0,
                16.0,
                16.0,
                40.0 + MediaQuery.of(context).padding.bottom, // Tăng thêm 40px + khoảng trống hệ thống
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  
                  _buildSectionTitle('1. Hình thức điều chỉnh'),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('Nâng giá'),
                          value: true,
                          groupValue: _isIncrease,
                          onChanged: isLoading ? null : (val) => setState(() => _isIncrease = val!),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('Hạ giá'),
                          value: false,
                          groupValue: _isIncrease,
                          onChanged: isLoading ? null : (val) => setState(() => _isIncrease = val!),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildSectionTitle('2. Loại điều chỉnh'),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Phần trăm (%)'),
                          value: 'percentage',
                          groupValue: _adjustmentType,
                          onChanged: isLoading ? null : (val) {
                            setState(() {
                              _adjustmentType = val!;
                              _valueController.clear();
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Số tiền (VND)'),
                          value: 'amount',
                          groupValue: _adjustmentType,
                          onChanged: isLoading ? null : (val) {
                            setState(() {
                              _adjustmentType = val!;
                              _valueController.clear();
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildSectionTitle('3. Giá trị điều chỉnh'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _valueController,
                    keyboardType: TextInputType.number,
                    enabled: !isLoading,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      if (_adjustmentType == 'amount') ThousandsSeparatorInputFormatter(),
                    ],
                    decoration: InputDecoration(
                      labelText: _adjustmentType == 'percentage' ? 'Nhập số phần trăm' : 'Nhập số tiền (VND)',
                      hintText: _adjustmentType == 'percentage' ? 'VD: 5' : 'VD: 10.000',
                      border: const OutlineInputBorder(),
                      suffixText: _adjustmentType == 'percentage' ? '%' : 'VND',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Vui lòng nhập giá trị';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle('4. Đối tượng sản phẩm'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _productTarget,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tất cả sản phẩm')),
                      DropdownMenuItem(value: 'foliar_fertilizer', child: Text('Phân bón lá')),
                      DropdownMenuItem(value: 'root_fertilizer', child: Text('Phân bón gốc')),
                    ],
                    onChanged: isLoading ? null : (val) => setState(() => _productTarget = val!),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle('5. Đối tượng đại lý'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _agentTarget,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tất cả đại lý (Cấp 1 & 2)')),
                      DropdownMenuItem(value: 'agent_1', child: Text('Chỉ Đại lý cấp 1')),
                      DropdownMenuItem(value: 'agent_2', child: Text('Chỉ Đại lý cấp 2')),
                    ],
                    onChanged: isLoading ? null : (val) => setState(() => _agentTarget = val!),
                  ),
                  
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56, // Tăng chiều cao từ 50 lên 56
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _onAdjustPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isIncrease ? Colors.green : Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12), // Thêm padding dọc
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Bo góc đẹp hơn
                        elevation: 2,
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Áp dụng điều chỉnh giá',
                              style: TextStyle(
                                fontSize: 17, // Tăng nhẹ kích thước chữ
                                fontWeight: FontWeight.bold,
                                height: 1.2, // Điều chỉnh line-height để tránh mất chân chữ
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    final String cleanValue = newValue.text.replaceAll('.', '');
    final double value = double.parse(cleanValue);
    
    final formatter = NumberFormat.decimalPattern('vi_VN');
    final String newText = formatter.format(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
