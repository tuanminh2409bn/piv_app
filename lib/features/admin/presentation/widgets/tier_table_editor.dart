import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/features/admin/data/models/discount_policy_model.dart';

class TierTableEditor extends StatefulWidget {
  final String title;
  final Color color;
  final List<DiscountTier> tiers;
  final ValueChanged<List<DiscountTier>> onChanged;

  const TierTableEditor({
    super.key,
    required this.title,
    required this.color,
    required this.tiers,
    required this.onChanged,
  });

  @override
  State<TierTableEditor> createState() => _TierTableEditorState();
}

class _TierTableEditorState extends State<TierTableEditor> {
  late List<DiscountTier> _localTiers;

  @override
  void initState() {
    super.initState();
    _localTiers = List.from(widget.tiers);
    _sortTiers();
  }

  @override
  void didUpdateWidget(covariant TierTableEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Chỉ cập nhật nếu danh sách thực sự thay đổi để tránh loop hoặc mất trạng thái focus
    // Tuy nhiên, với logic hiện tại, parent rebuild thường xuyên, nên ta cần cẩn trọng.
    // Tạm thời reset nếu độ dài khác nhau hoặc deep check (đơn giản hoá bằng check độ dài)
    if (oldWidget.tiers.length != widget.tiers.length) {
      _localTiers = List.from(widget.tiers);
      _sortTiers();
    }
  }

  void _sortTiers() {
    _localTiers.sort((a, b) => b.minAmount.compareTo(a.minAmount)); // Giảm dần
  }

  void _addTier() {
    setState(() {
      _localTiers.add(DiscountTier(minAmount: 0, rate: 0));
      _sortTiers();
    });
    widget.onChanged(_localTiers);
  }

  void _removeTier(int index) {
    setState(() {
      _localTiers.removeAt(index);
    });
    widget.onChanged(_localTiers);
  }

  void _updateTier(int index, double amount, double rate) {
    setState(() {
      _localTiers[index] = DiscountTier(minAmount: amount, rate: rate);
      _sortTiers();
    });
    widget.onChanged(_localTiers);
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern('vi');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  onPressed: _addTier,
                  tooltip: 'Thêm mức chiết khấu',
                ),
              ],
            ),
          ),
          if (_localTiers.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('Chưa có cấu hình')),
          ..._localTiers.asMap().entries.map((entry) {
            final index = entry.key;
            final tier = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      // Format giá trị ban đầu: 1000000 -> 1.000.000
                      initialValue: numberFormat.format(tier.minAmount),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                      decoration: const InputDecoration(labelText: 'Doanh số tối thiểu (VND)', isDense: true, border: OutlineInputBorder()),
                      onChanged: (val) {
                        String cleanVal = val.replaceAll('.', '');
                        _updateTier(index, double.tryParse(cleanVal) ?? 0, tier.rate);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_right_alt, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: (tier.rate * 100).toStringAsFixed(1),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Chiết khấu (%)', isDense: true, border: OutlineInputBorder(), suffixText: '%'),
                      onChanged: (val) => _updateTier(index, tier.minAmount, (double.tryParse(val) ?? 0) / 100),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeTier(index),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    String value = newValue.text.replaceAll('.', ''); // Xóa dấu chấm cũ
    final formatter = NumberFormat.decimalPattern('vi');
    String newText = formatter.format(double.tryParse(value) ?? 0);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
