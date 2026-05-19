import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/core/theme/nature_background_painter.dart';
import 'package:piv_app/core/utils/responsive.dart';
import 'package:piv_app/common/widgets/responsive_wrapper.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/sales_commitment/presentation/bloc/admin/sales_commitment_admin_cubit.dart';

class ProposeCommitmentFormPage extends StatefulWidget {
  final UserModel targetAgent;

  const ProposeCommitmentFormPage({super.key, required this.targetAgent});

  static Route<void> route(SalesCommitmentAdminCubit cubit, UserModel agent) {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: ProposeCommitmentFormPage(targetAgent: agent),
      ),
    );
  }

  @override
  State<ProposeCommitmentFormPage> createState() =>
      _ProposeCommitmentFormPageState();
}

class _ProposeCommitmentFormPageState extends State<ProposeCommitmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _targetAmountController = TextEditingController();
  final _detailsTextController = TextEditingController();
  DateTimeRange? _selectedDateRange;

  @override
  void dispose() {
    _targetAmountController.dispose();
    _detailsTextController.dispose();
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

      final targetAmount = double.tryParse(_targetAmountController.text.replaceAll('.', ''));
      final detailsText = _detailsTextController.text.trim();

      context.read<SalesCommitmentAdminCubit>().proposeSalesCommitment(
            agentId: widget.targetAgent.id,
            targetAmount: targetAmount!,
            startDate: _selectedDateRange!.start,
            endDate: _selectedDateRange!.end,
            detailsText: detailsText,
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
        leading: const BackButton(color: Colors.white),
        title: Text('Đề xuất Cam kết cho ${widget.targetAgent.displayName}'),
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
          
          BlocListener<SalesCommitmentAdminCubit, SalesCommitmentAdminState>(
            listener: (context, state) {
              if (state.status == SalesCommitmentAdminStatus.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(state.errorMessage ?? 'Gửi đề xuất thất bại'),
                      backgroundColor: AppTheme.errorRed),
                );
              } else if (state.status == SalesCommitmentAdminStatus.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Gửi đề xuất cam kết thành công!'),
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
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.handshake_outlined,
                                    color: AppTheme.primaryGreen, size: 32),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tạo Đề Xuất Mới',
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textDark),
                                    ),
                                    Text(
                                      'Gửi đề xuất tham gia cam kết cho đại lý.',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          const Text('Đại lý nhận đề xuất:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark)),
                          const SizedBox(height: 8),
                          Text('${widget.targetAgent.displayName} (${widget.targetAgent.phoneNumber})',
                            style: const TextStyle(fontSize: 16, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          
                          // Thời gian cam kết
                          const Text('Thời gian áp dụng:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _selectDateRange,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 20),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppTheme.primaryGreen
                                        .withValues(alpha: 0.3),
                                    width: 1.5),
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      color: AppTheme.primaryGreen),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      _selectedDateRange == null
                                          ? 'Chọn ngày bắt đầu - kết thúc'
                                          : '${dateFormatter.format(_selectedDateRange!.start)} - ${dateFormatter.format(_selectedDateRange!.end)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _selectedDateRange == null
                                            ? Colors.grey
                                            : AppTheme.textDark,
                                        fontWeight: _selectedDateRange != null
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (_selectedDateRange != null)
                                    const Icon(Icons.check_circle,
                                        color: Colors.green, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Mức cam kết
                          const Text('Mức doanh số cam kết (VNĐ):',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _targetAmountController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen),
                            decoration: InputDecoration(
                              hintText: 'Nhập số tiền...',
                              hintStyle: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal),
                              prefixIcon: const Icon(Icons.monetization_on,
                                  color: AppTheme.primaryGreen),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                    color: AppTheme.primaryGreen
                                        .withValues(alpha: 0.3),
                                    width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                    color: AppTheme.primaryGreen
                                        .withValues(alpha: 0.3),
                                    width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                    color: AppTheme.primaryGreen, width: 2),
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              TextInputFormatter.withFunction(
                                  (oldValue, newValue) {
                                if (newValue.text.isEmpty) return newValue;
                                final intValue = int.parse(newValue.text);
                                final newString =
                                    currencyFormatter.format(intValue);
                                return TextEditingValue(
                                  text: newString,
                                  selection: TextSelection.collapsed(
                                      offset: newString.length),
                                );
                              }),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập mức doanh số cam kết';
                              }
                              final amount = double.tryParse(
                                  value.replaceAll('.', ''));
                              if (amount == null || amount <= 0) {
                                return 'Số tiền không hợp lệ';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          // Chi tiết quyền lợi / ghi chú
                          const Text('Chi tiết quyền lợi & Ghi chú:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _detailsTextController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: 'Mô tả chi tiết các phần thưởng, quyền lợi (ví dụ: thưởng chuyến du lịch, thưởng vàng...) nếu đại lý đạt cam kết.',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập chi tiết quyền lợi';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: BlocBuilder<SalesCommitmentAdminCubit,
                                SalesCommitmentAdminState>(
                              builder: (context, state) {
                                final isLoading = state.status ==
                                    SalesCommitmentAdminStatus.loading;
                                return ElevatedButton(
                                  onPressed: isLoading ? null : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryGreen,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white)
                                      : const Text(
                                          'Gửi Đề Xuất',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                );
                              },
                            ),
                          ),
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