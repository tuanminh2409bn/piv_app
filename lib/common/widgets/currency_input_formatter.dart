import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// Tách Formatter ra file riêng để dễ tái sử dụng
class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('vi_VN');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    // Nếu xóa hết -> trả về rỗng
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Chỉ giữ lại số
    final cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    try {
      // Parse thành số nguyên (vì không cần phần thập phân)
      final number = int.parse(cleanText);
      // Format lại với dấu chấm
      final formattedText = _formatter.format(number);

      return newValue.copyWith(
        text: formattedText,
        // Di chuyển con trỏ về cuối
        selection: TextSelection.collapsed(offset: formattedText.length),
      );
    } catch (e) {
      // Trả về giá trị cũ nếu có lỗi parse (hiếm khi xảy ra với digitsOnly)
      return oldValue;
    }
  }

  // Hàm helper để parse ngược lại
  static num? parse(String formattedString) {
    if (formattedString.isEmpty) return null;
    final cleanText = formattedString.replaceAll('.', ''); // Xóa dấu chấm
    return num.tryParse(cleanText);
  }

  // Hàm helper để format số (double hoặc int) thành chuỗi không có ".0"
  static String formatNumber(num? number) {
    if (number == null) return '';
    final formatter = NumberFormat.decimalPattern('vi_VN');
    // Nếu là số nguyên hoặc phần thập phân là 0, format như số nguyên
    if (number is int || number.truncateToDouble() == number) {
      return formatter.format(number.toInt());
    } else {
      // Giữ lại phần thập phân nếu có (ví dụ: cho %)
      return formatter.format(number);
    }
  }
}
