import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/sales_rep/presentation/bloc/sales_rep_cubit.dart';

// --- BẮT ĐẦU PHẦN MỚI: Currency Formatter ---
// (Đây là class tái sử dụng từ trang admin)
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

class SalesRepDebtManagementPage extends StatelessWidget {
  const SalesRepDebtManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<SalesRepCubit, SalesRepState>(
        listener: (context, state) {
          if (state.status == SalesRepStatus.error && state.errorMessage != null) {
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
          if (state.status == SalesRepStatus.loading && state.myAgents.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.myAgents.isEmpty) {
            return const Center(child: Text('Bạn chưa có đại lý nào để quản lý công nợ.'));
          }

          final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

          return RefreshIndicator(
            onRefresh: () async => context.read<SalesRepCubit>().fetchMyAgents(),
            child: ListView.separated(
              itemCount: state.myAgents.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = state.myAgents[index];
                return ListTile(
                  title: Text(user.displayName ?? 'Chưa có tên'),
                  subtitle: Text(user.email ?? 'Chưa có email'),
                  trailing: Text(
                    currencyFormat.format(user.debtAmount),
                    style: TextStyle(
                      color: user.debtAmount > 0 ? Colors.red : Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () => _showUpdateDebtDialog(context, user),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // --- BẮT ĐẦU SỬA ĐỔI DIALOG ---
  void _showUpdateDebtDialog(BuildContext context, UserModel user) {
    final numberFormat = NumberFormat.decimalPattern('vi_VN');
    final debtController = TextEditingController(text: numberFormat.format(user.debtAmount));
    final formKey = GlobalKey<FormState>();
    final cubit = context.read<SalesRepCubit>();

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

                  cubit.updateAgentDebt(
                    agentId: user.id,
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
// --- KẾT THÚC SỬA ĐỔI DIALOG ---
}