// lib/features/sales_commitment/presentation/pages/create_commitment_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/core/theme/nature_background_painter.dart';
import 'package:piv_app/core/utils/responsive.dart';
import 'package:piv_app/common/widgets/responsive_wrapper.dart';
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
  State<CreateCommitmentFormPage> createState() =>
      _CreateCommitmentFormPageState();
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
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
          const SnackBar(
              content: Text('Vui lòng chọn khoảng thời gian cam kết.'),
              backgroundColor: AppTheme.errorRed),
        );
        return;
      }

      final targetAmount =
          double.tryParse(_targetAmountController.text.replaceAll('.', ''));

      context.read<SalesCommitmentAgentCubit>().createCommitment(
            targetAmount: targetAmount!,
            startDate: _selectedDateRange!.start,
            endDate: _selectedDateRange!.end,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.decimalPattern('vi_VN');
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final bool isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Đăng ký Cam kết'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Pattern
          Positioned.fill(
            child: CustomPaint(
              painter: NatureBackgroundPainter(
                color1: AppTheme.primaryGreen.withValues(alpha: 0.05),
                color2: AppTheme.secondaryGreen.withValues(alpha: 0.03),
                accent: AppTheme.accentGold.withValues(alpha: 0.1),
              ),
            ),
          ),
          
          BlocListener<SalesCommitmentAgentCubit, SalesCommitmentAgentState>(
            listener: (context, state) {
              if (state.status == SalesCommitmentAgentStatus.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(state.errorMessage ?? 'Đăng ký thất bại'),
                      backgroundColor: AppTheme.errorRed),
                );
              } else if (state.status == SalesCommitmentAgentStatus.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Đăng ký cam kết thành công!'),
                      backgroundColor: Colors.green),
                );
                Navigator.of(context).pop();
              }
            },
            child: ResponsiveWrapper(
              maxWidth: 600,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mục tiêu doanh thu',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              )),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _targetAmountController,
                            decoration: InputDecoration(
                              labelText: 'Doanh thu mục tiêu (VNĐ)',
                              hintText: 'Nhập số tiền mục tiêu',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.monetization_on_outlined, color: AppTheme.primaryGreen),
                              suffixText: 'VNĐ',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              TextInputFormatter.withFunction(
                                (oldValue, newValue) {
                                  if (newValue.text.isEmpty) return newValue;
                                  final number = int.parse(newValue.text);
                                  final formattedText =
                                      currencyFormatter.format(number);
                                  return newValue.copyWith(
                                    text: formattedText,
                                    selection: TextSelection.collapsed(
                                        offset: formattedText.length),
                                  );
                                },
                              ),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập doanh thu mục tiêu';
                              }
                              final number = int.tryParse(
                                  value.replaceAll('.', ''));
                              if (number == null || number <= 0) {
                                return 'Doanh thu phải là một số lớn hơn 0';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          Text('Khoảng thời gian',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              )),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: _selectDateRange,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, color: AppTheme.primaryGreen, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedDateRange == null
                                          ? 'Chọn ngày bắt đầu - kết thúc'
                                          : '${dateFormatter.format(_selectedDateRange!.start)} - ${dateFormatter.format(_selectedDateRange!.end)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _selectedDateRange == null ? AppTheme.textGrey : AppTheme.textDark,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down, color: AppTheme.textGrey),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),
                          SizedBox(
                            width: double.infinity,
                            child: BlocBuilder<SalesCommitmentAgentCubit,
                                SalesCommitmentAgentState>(
                              builder: (context, state) {
                                return ElevatedButton(
                                  onPressed: state.status ==
                                          SalesCommitmentAgentStatus.loading
                                      ? null
                                      : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 8,
                                    shadowColor: AppTheme.primaryGreen.withValues(alpha: 0.3),
                                  ),
                                  child: state.status ==
                                          SalesCommitmentAgentStatus.loading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2))
                                      : const Text('XÁC NHẬN ĐĂNG KÝ', 
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
                                );
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}