//lib/features/admin/presentation/pages/admin_debt_management_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_users_cubit.dart';
import 'package:intl/intl.dart';

// --- BẮT ĐẦU PHẦN MỚI: Currency Formatter ---
class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('vi_VN');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final number = int.parse(cleanText);
    final formattedText = _formatter.format(number);

    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
// --- KẾT THÚC PHẦN MỚI ---


class AdminDebtManagementPage extends StatelessWidget {
  const AdminDebtManagementPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (context) => sl<AdminUsersCubit>()..fetchAndGroupUsers(),
        child: const AdminDebtManagementPage(),
      ),
    );
  }

  // --- BẮT ĐẦU SỬA ĐỔI DIALOG ---
  void _showUpdateDebtDialog(BuildContext context, UserModel user) {
    final numberFormat = NumberFormat.decimalPattern('vi_VN');
    final debtController = TextEditingController(text: numberFormat.format(user.debtAmount));
    final formKey = GlobalKey<FormState>();
    final cubit = context.read<AdminUsersCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cập nhật công nợ'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đại lý: ${user.displayName ?? user.email}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: debtController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                  // SỬ DỤNG FORMATTER MỚI
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Số tiền công nợ mới',
                    suffixText: 'đ',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số tiền';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  // Chuyển đổi chuỗi đã định dạng về số
                  final cleanValue = debtController.text.replaceAll('.', '');
                  final newDebtAmount = double.tryParse(cleanValue) ?? 0.0;

                  cubit.updateUserDebt(
                    userId: user.id,
                    newDebtAmount: newDebtAmount,
                  );
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Cập nhật'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Công nợ'),
      ),
      body: BlocConsumer<AdminUsersCubit, AdminUsersState>( // Sửa thành BlocConsumer
        listener: (context, state) {
          if (state.status == AdminUsersStatus.success && state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
          }
        },
        builder: (context, state) {
          if (state.status == AdminUsersStatus.loading || state.status == AdminUsersStatus.updating) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == AdminUsersStatus.error) {
            return Center(child: Text(state.errorMessage ?? 'Đã xảy ra lỗi'));
          }

          final agents = state.allUsers.where((user) =>
          !user.isAdmin && !user.isAccountant && !user.isSalesRep
          ).toList();

          if (agents.isEmpty) {
            return const Center(child: Text('Không tìm thấy đại lý nào.'));
          }

          return ListView.separated( // Sửa thành ListView.separated để đẹp hơn
            itemCount: agents.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = agents[index];
              return ListTile(
                title: Text(user.displayName ?? 'Chưa có tên'),
                subtitle: Text(user.email ?? 'Chưa có email'),
                trailing: Text(
                  currencyFormat.format(user.debtAmount), // Định dạng tiền tệ
                  style: TextStyle(
                    color: user.debtAmount > 0 ? Colors.red : Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  // --- GỌI HÀM HIỂN THỊ DIALOG ---
                  _showUpdateDebtDialog(context, user);
                  // ------------------------------
                },
              );
            },
          );
        },
      ),
    );
  }
}