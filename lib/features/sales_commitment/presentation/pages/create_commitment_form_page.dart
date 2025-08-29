// lib/features/sales_commitment/presentation/pages/create_commitment_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/features/sales_commitment/presentation/bloc/agent/sales_commitment_agent_cubit.dart';

class CreateCommitmentFormPage extends StatefulWidget {
  const CreateCommitmentFormPage({super.key});

  static Route<void> route(SalesCommitmentAgentCubit cubit) {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const CreateCommitmentFormPage(),
      ),
    );
  }

  @override
  State<CreateCommitmentFormPage> createState() => _CreateCommitmentFormPageState();
}

class _CreateCommitmentFormPageState extends State<CreateCommitmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _targetAmountController = TextEditingController();
  DateTimeRange? _selectedDateRange;

  @override
  void dispose() {
    _targetAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final newDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, 1),
      lastDate: DateTime(now.year + 2),
      locale: const Locale('vi', 'VN'),
      helpText: 'CHỌN KHOẢNG THỜI GIAN CAM KẾT',
    );

    if (newDateRange != null) {
      setState(() {
        _selectedDateRange = newDateRange;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDateRange == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn khoảng thời gian cam kết.'), backgroundColor: Colors.red),
        );
        return;
      }

      final targetAmount = double.tryParse(_targetAmountController.text.replaceAll('.', ''));

      context.read<SalesCommitmentAgentCubit>().createCommitment(
        targetAmount: targetAmount!,
        startDate: _selectedDateRange!.start,
        endDate: _selectedDateRange!.end,
      );
      // Quay lại màn hình trước đó sau khi gửi
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.decimalPattern('vi_VN');
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký Cam kết'),
      ),
      body: BlocListener<SalesCommitmentAgentCubit, SalesCommitmentAgentState>(
        listener: (context, state) {
          if (state.status == SalesCommitmentAgentStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Đăng ký thất bại'), backgroundColor: Colors.red),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Đặt mục tiêu doanh thu', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _targetAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Doanh thu mục tiêu (VNĐ)',
                    border: OutlineInputBorder(),
                    suffixText: 'VNĐ',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction(
                          (oldValue, newValue) {
                        if (newValue.text.isEmpty) return newValue;
                        final number = int.parse(newValue.text);
                        final formattedText = currencyFormatter.format(number);
                        return newValue.copyWith(
                          text: formattedText,
                          selection: TextSelection.collapsed(offset: formattedText.length),
                        );
                      },
                    ),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập doanh thu mục tiêu';
                    }
                    final number = int.tryParse(value.replaceAll('.', ''));
                    if (number == null || number <= 0) {
                      return 'Doanh thu phải là một số lớn hơn 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text('Chọn khoảng thời gian', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _selectedDateRange == null
                        ? 'Chọn ngày bắt đầu và kết thúc'
                        : '${dateFormatter.format(_selectedDateRange!.start)} - ${dateFormatter.format(_selectedDateRange!.end)}',
                  ),
                  onPressed: _selectDateRange,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    alignment: Alignment.centerLeft,
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: BlocBuilder<SalesCommitmentAgentCubit, SalesCommitmentAgentState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        onPressed: state.status == SalesCommitmentAgentStatus.loading ? null : _submitForm,
                        child: state.status == SalesCommitmentAgentStatus.loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('XÁC NHẬN ĐĂNG KÝ'),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}