import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';
import 'package:piv_app/features/vouchers/presentation/bloc/voucher_management_cubit.dart';

class VoucherFormPage extends StatefulWidget {
  final VoucherModel? voucher;

  const VoucherFormPage({super.key, this.voucher});

  static PageRoute<void> route({VoucherModel? voucher}) {
    return MaterialPageRoute<void>(
      builder: (context) => BlocProvider.value(
        value: BlocProvider.of<VoucherManagementCubit>(context),
        child: VoucherFormPage(voucher: voucher),
      ),
    );
  }

  @override
  State<VoucherFormPage> createState() => _VoucherFormPageState();
}

class _VoucherFormPageState extends State<VoucherFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _discountValueController;
  late final TextEditingController _minOrderValueController;
  late final TextEditingController _maxDiscountAmountController;
  late final TextEditingController _maxUsesController;
  late final TextEditingController _expiresAtController;

  DiscountType _discountType = DiscountType.fixedAmount;
  DateTime _expiresAt = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    final v = widget.voucher;
    _codeController = TextEditingController(text: v?.id ?? '');
    _descriptionController = TextEditingController(text: v?.description ?? '');
    _discountValueController = TextEditingController(text: v?.discountValue.toString() ?? '');
    _minOrderValueController = TextEditingController(text: v?.minOrderValue.toString() ?? '0');
    _maxDiscountAmountController = TextEditingController(text: v?.maxDiscountAmount?.toString() ?? '');
    _maxUsesController = TextEditingController(text: v?.maxUses.toString() ?? '1');
    _expiresAtController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(v?.expiresAt.toDate() ?? _expiresAt));

    if (v != null) {
      _discountType = v.discountType;
      _expiresAt = v.expiresAt.toDate();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _minOrderValueController.dispose();
    _maxDiscountAmountController.dispose();
    _maxUsesController.dispose();
    _expiresAtController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      context.read<VoucherManagementCubit>().saveVoucher(
        id: widget.voucher?.id,
        code: _codeController.text.trim(),
        description: _descriptionController.text.trim(),
        discountType: _discountType,
        discountValue: double.tryParse(_discountValueController.text) ?? 0,
        minOrderValue: double.tryParse(_minOrderValueController.text) ?? 0,
        maxDiscountAmount: _discountType == DiscountType.percentage
            ? double.tryParse(_maxDiscountAmountController.text)
            : null,
        maxUses: int.tryParse(_maxUsesController.text) ?? 1,
        expiresAt: _expiresAt,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.voucher == null ? 'Tạo Voucher mới' : 'Sửa Voucher'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submitForm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Mã Voucher (viết liền, không dấu)'),
                enabled: widget.voucher == null, // Chỉ cho sửa mã khi tạo mới
                validator: (value) => (value?.isEmpty ?? true) ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả ngắn'),
                validator: (value) => (value?.isEmpty ?? true) ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<DiscountType>(
                value: _discountType,
                decoration: const InputDecoration(labelText: 'Loại giảm giá'),
                items: const [
                  DropdownMenuItem(value: DiscountType.fixedAmount, child: Text('Số tiền cố định (VNĐ)')),
                  DropdownMenuItem(value: DiscountType.percentage, child: Text('Theo phần trăm (%)')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _discountType = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _discountValueController,
                decoration: InputDecoration(labelText: _discountType == DiscountType.percentage ? 'Phần trăm giảm' : 'Số tiền giảm'),
                keyboardType: TextInputType.number,
                validator: (value) => (value?.isEmpty ?? true) ? 'Không được để trống' : null,
              ),
              if (_discountType == DiscountType.percentage) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _maxDiscountAmountController,
                  decoration: const InputDecoration(labelText: 'Số tiền giảm tối đa (VNĐ) (bỏ trống nếu không giới hạn)'),
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _minOrderValueController,
                decoration: const InputDecoration(labelText: 'Giá trị đơn hàng tối thiểu (VNĐ)'),
                keyboardType: TextInputType.number,
                validator: (value) => (value?.isEmpty ?? true) ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxUsesController,
                decoration: const InputDecoration(labelText: 'Số lần sử dụng tối đa (nhập 0 nếu không giới hạn)'),
                keyboardType: TextInputType.number,
                validator: (value) => (value?.isEmpty ?? true) ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _expiresAtController,
                decoration: const InputDecoration(labelText: 'Ngày hết hạn'),
                readOnly: true,
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _expiresAt,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _expiresAt = pickedDate;
                      _expiresAtController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}