import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/sales_rep/presentation/bloc/sales_rep_cubit.dart';

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

  void _showUpdateDebtDialog(BuildContext context, UserModel user) {
    final debtController = TextEditingController(text: user.debtAmount.toStringAsFixed(0));
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
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Số tiền công nợ mới',
                    suffixText: 'đ',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số tiền';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Số tiền không hợp lệ';
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
                  final newDebtAmount = double.parse(debtController.text);
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
}