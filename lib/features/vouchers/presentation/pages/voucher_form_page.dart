import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Thêm import này
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';
import 'package:piv_app/features/vouchers/presentation/bloc/voucher_management_cubit.dart';
// --- THÊM IMPORT FORMATTER ---
import 'package:piv_app/common/widgets/currency_input_formatter.dart';
// --- KẾT THÚC THÊM ---


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
  late final TextEditingController _buyQuantityController;
  late final TextEditingController _getQuantityController;

  DiscountType _discountType = DiscountType.fixedAmount;
  DateTime _expiresAt = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    final v = widget.voucher;

    _codeController = TextEditingController(text: v?.id ?? '');
    _descriptionController = TextEditingController(text: v?.description ?? '');
    _discountValueController = TextEditingController(text: CurrencyInputFormatter.formatNumber(v?.discountValue) ?? '');
    _minOrderValueController = TextEditingController(text: CurrencyInputFormatter.formatNumber(v?.minOrderValue ?? 0));
    _maxDiscountAmountController = TextEditingController(text: CurrencyInputFormatter.formatNumber(v?.maxDiscountAmount) ?? '');
    _maxUsesController = TextEditingController(text: CurrencyInputFormatter.formatNumber(v?.maxUses ?? 1));
    _buyQuantityController = TextEditingController(text: v?.buyQuantity?.toString() ?? '');
    _getQuantityController = TextEditingController(text: v?.getQuantity?.toString() ?? '');
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
    _buyQuantityController.dispose();
    _getQuantityController.dispose();
    _expiresAtController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final discountValueNum = CurrencyInputFormatter.parse(_discountValueController.text);
      final minOrderValueNum = CurrencyInputFormatter.parse(_minOrderValueController.text);
      final maxDiscountAmountNum = CurrencyInputFormatter.parse(_maxDiscountAmountController.text);
      final maxUsesNum = CurrencyInputFormatter.parse(_maxUsesController.text);
      final buyQtyNum = int.tryParse(_buyQuantityController.text);
      final getQtyNum = int.tryParse(_getQuantityController.text);

      if (_discountType != DiscountType.buyXGetY && discountValueNum == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng kiểm tra lại giá trị giảm giá.'), backgroundColor: Colors.orange,)
        );
        return;
      }

      if (_discountType == DiscountType.buyXGetY && (buyQtyNum == null || getQtyNum == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng nhập đầy đủ số lượng mua và tặng.'), backgroundColor: Colors.orange,)
        );
        return;
      }

      context.read<VoucherManagementCubit>().saveVoucher(
        id: widget.voucher?.id, 
        code: _codeController.text.trim().toUpperCase(), 
        description: _descriptionController.text.trim(),
        discountType: _discountType,
        discountValue: discountValueNum?.toDouble() ?? 0.0,
        minOrderValue: minOrderValueNum?.toDouble() ?? 0.0,
        maxDiscountAmount: _discountType == DiscountType.percentage
            ? maxDiscountAmountNum?.toDouble() 
            : null,
        maxUses: maxUsesNum?.toInt() ?? 0,
        expiresAt: _expiresAt,
        buyQuantity: _discountType == DiscountType.buyXGetY ? buyQtyNum : null,
        getQuantity: _discountType == DiscountType.buyXGetY ? getQtyNum : null,
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
                decoration: const InputDecoration(labelText: 'Mã Voucher (viết liền, không dấu, viết hoa)'),
                textCapitalization: TextCapitalization.characters, // Tự viết hoa
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')), // Chỉ cho phép chữ hoa và số
                ],
                enabled: widget.voucher == null, // Chỉ cho sửa mã khi tạo mới
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Không được để trống';
                  if (value.contains(' ')) return 'Mã không được chứa khoảng trắng';
                  return null;
                },
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
                  DropdownMenuItem(value: DiscountType.buyXGetY, child: Text('Mua X thùng tặng Y thùng')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _discountType = value;
                      if (_discountType != DiscountType.percentage) _maxDiscountAmountController.clear();
                      if (_discountType != DiscountType.buyXGetY) {
                        _buyQuantityController.clear();
                        _getQuantityController.clear();
                      } else {
                        _discountValueController.text = '0';
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              if (_discountType == DiscountType.buyXGetY) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _buyQuantityController,
                        decoration: const InputDecoration(labelText: 'Mua số lượng (thùng)', suffixText: 'thùng'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) => (value?.isEmpty ?? true) ? 'Bắt buộc' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _getQuantityController,
                        decoration: const InputDecoration(labelText: 'Tặng số lượng (thùng)', suffixText: 'thùng'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) => (value?.isEmpty ?? true) ? 'Bắt buộc' : null,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                TextFormField(
                  controller: _discountValueController,
                  decoration: InputDecoration(
                    labelText: _discountType == DiscountType.percentage ? 'Phần trăm giảm (%)' : 'Số tiền giảm (VNĐ)',
                    suffixText: _discountType == DiscountType.percentage ? '%' : 'VNĐ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Không được để trống';
                    final parsedValue = CurrencyInputFormatter.parse(value);
                    if (parsedValue == null) return 'Giá trị không hợp lệ';
                    if (_discountType == DiscountType.percentage && (parsedValue <= 0 || parsedValue > 100)) {
                      return 'Phần trăm phải từ 1 đến 100';
                    }
                    if (_discountType == DiscountType.fixedAmount && parsedValue <= 0) {
                      return 'Số tiền phải lớn hơn 0';
                    }
                    return null;
                  },
                ),
              ],
              // Chỉ hiển thị maxDiscountAmount khi loại là percentage
              if (_discountType == DiscountType.percentage) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _maxDiscountAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Số tiền giảm tối đa (VNĐ)',
                    hintText: 'Bỏ trống nếu không giới hạn',
                    suffixText: 'VNĐ',
                  ),
                  // --- SỬA ĐỔI: Thêm keyboardType và inputFormatters ---
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  // --- KẾT THÚC SỬA ĐỔI ---
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final parsedValue = CurrencyInputFormatter.parse(value);
                      if (parsedValue == null || parsedValue <= 0) {
                        return 'Số tiền phải lớn hơn 0';
                      }
                    }
                    return null; // Cho phép bỏ trống
                  },
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _minOrderValueController,
                decoration: const InputDecoration(
                  labelText: 'Giá trị đơn hàng tối thiểu (VNĐ)',
                  suffixText: 'VNĐ',
                ),
                // --- SỬA ĐỔI: Thêm keyboardType và inputFormatters ---
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                // --- KẾT THÚC SỬA ĐỔI ---
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Không được để trống';
                  final parsedValue = CurrencyInputFormatter.parse(value);
                  if (parsedValue == null || parsedValue < 0) {
                    return 'Giá trị không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxUsesController,
                decoration: const InputDecoration(labelText: 'Số lần sử dụng tối đa (0 = không giới hạn)'),
                // --- SỬA ĐỔI: Thêm keyboardType và inputFormatters ---
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(), // Vẫn dùng để có dấu chấm nếu số lớn
                ],
                // --- KẾT THÚC SỬA ĐỔI ---
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Không được để trống';
                  final parsedValue = CurrencyInputFormatter.parse(value);
                  if (parsedValue == null || parsedValue < 0) {
                    return 'Số lần không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _expiresAtController,
                decoration: const InputDecoration(
                  labelText: 'Ngày hết hạn',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  // Đảm bảo ngày ban đầu không sớm hơn ngày hiện tại
                  DateTime initial = _expiresAt.isBefore(DateTime.now()) ? DateTime.now() : _expiresAt;
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime.now(), // Không cho chọn ngày quá khứ
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)), // Giới hạn 5 năm
                  );
                  if (pickedDate != null) {
                    setState(() {
                      // Set về cuối ngày để bao gồm cả ngày chọn
                      _expiresAt = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, 23, 59, 59);
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
