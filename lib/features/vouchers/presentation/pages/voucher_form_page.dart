import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';
import 'package:piv_app/features/vouchers/presentation/bloc/voucher_management_cubit.dart';

class VoucherFormPage extends StatelessWidget {
  const VoucherFormPage({super.key});

  static PageRoute<bool> route() {
    return MaterialPageRoute<bool>(builder: (_) => const VoucherFormPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<VoucherManagementCubit>(),
      child: const VoucherFormView(),
    );
  }
}

class VoucherFormView extends StatefulWidget {
  const VoucherFormView({super.key});
  @override
  State<VoucherFormView> createState() => _VoucherFormViewState();
}

class _VoucherFormViewState extends State<VoucherFormView> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _maxUsesController = TextEditingController(text: '1');
  final _expiresAtController = TextEditingController();

  DiscountType _discountType = DiscountType.fixedAmount;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _maxUsesController.dispose();
    _expiresAtController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _expiresAtController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _createVoucher() {
    if (_formKey.currentState!.validate()) {
      context.read<VoucherManagementCubit>().createVoucher(
        code: _codeController.text.trim(),
        description: _descriptionController.text.trim(),
        discountType: _discountType,
        discountValue: double.parse(_discountValueController.text.trim()),
        expiresAt: _selectedDate!,
        maxUses: int.tryParse(_maxUsesController.text.trim()) ?? 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo Voucher mới')),
      body: BlocListener<VoucherManagementCubit, VoucherManagementState>(
        listener: (context, state) {
          if (state.status == VoucherStatus.success) {
            Navigator.of(context).pop(true); // Trả về true để trang trước biết cần làm mới
          } else if (state.status == VoucherStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage ?? 'Có lỗi xảy ra')));
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildTextField(_codeController, 'Mã Voucher (Ví dụ: PIV2025)'),
              _buildTextField(_descriptionController, 'Mô tả ngắn'),
              const SizedBox(height: 16),
              SegmentedButton<DiscountType>(
                segments: const [
                  ButtonSegment(value: DiscountType.fixedAmount, label: Text('Số tiền cố định')),
                  ButtonSegment(value: DiscountType.percentage, label: Text('Theo phần trăm (%)')),
                ],
                selected: {_discountType},
                onSelectionChanged: (Set<DiscountType> newSelection) {
                  setState(() => _discountType = newSelection.first);
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(_discountValueController, 'Giá trị giảm', keyboardType: TextInputType.number),
              _buildTextField(_expiresAtController, 'Ngày hết hạn', readOnly: true, onTap: () => _selectDate(context)),
              _buildTextField(_maxUsesController, 'Số lần sử dụng tối đa (0 là không giới hạn)', keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _createVoucher,
                child: const Text('TẠO VOUCHER'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool readOnly = false, VoidCallback? onTap, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (value) => value == null || value.trim().isEmpty ? '$label không được để trống' : null,
      ),
    );
  }
}