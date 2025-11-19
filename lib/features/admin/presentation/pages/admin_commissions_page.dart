// lib/features/admin/presentation/pages/admin_commissions_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/commission_model.dart';
import 'package:piv_app/data/models/commission_with_details.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_commissions_cubit.dart';

class AdminCommissionsPage extends StatelessWidget {
  const AdminCommissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AdminCommissionsCubit>()..fetchAllData(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý Hoa hồng'),
        ),
        // --- ĐÃ SỬA: Bỏ Stack và lớp phủ mờ, hiển thị trực tiếp View ---
        body: const AdminCommissionsView(),
        // -------------------------------------------------------------
      ),
    );
  }
}

// ... (Phần code còn lại của AdminCommissionsView và các widget con giữ nguyên như cũ)
class AdminCommissionsView extends StatelessWidget {
  const AdminCommissionsView({super.key});

  Future<void> _selectDateRange(BuildContext context, AdminCommissionsState state) async {
    final newDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: state.startDate != null && state.endDate != null
          ? DateTimeRange(start: state.startDate!, end: state.endDate!)
          : null,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('vi', 'VN'),
    );

    if (newDateRange != null) {
      context.read<AdminCommissionsCubit>().setDateRange(newDateRange);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilters(context),
        const Divider(height: 1, thickness: 1),
        Expanded(
          child: BlocConsumer<AdminCommissionsCubit, AdminCommissionsState>(
            listener: (context, state) {
              if (state.status == AdminCommissionsStatus.error && state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
              }
            },
            builder: (context, state) {
              if (state.status == AdminCommissionsStatus.loading && state.allCommissions.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.allCommissions.isEmpty) {
                return const Center(child: Text('Không có dữ liệu hoa hồng.'));
              }
              if (state.filteredCommissions.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => context.read<AdminCommissionsCubit>().fetchAllData(),
                  child: const SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Center(heightFactor: 5, child: Text('Không có hoa hồng nào khớp với bộ lọc.'))
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => context.read<AdminCommissionsCubit>().fetchAllData(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: state.filteredCommissions.length,
                  itemBuilder: (context, index) {
                    final commissionItem = state.filteredCommissions[index];
                    return _buildCommissionCard(context, commissionItem);
                  },
                ),
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: BlocBuilder<AdminCommissionsCubit, AdminCommissionsState>(
        builder: (context, state) {
          final dateFormat = DateFormat('dd/MM/yyyy');
          final startDateText = state.startDate != null ? dateFormat.format(state.startDate!) : 'Từ ngày';
          final endDateText = state.endDate != null ? dateFormat.format(state.endDate!) : 'Đến ngày';

          return Column(
            children: [
              if (state.salesReps.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: state.selectedSalesRepId,
                  isExpanded: true,
                  hint: const Text('Tất cả Nhân viên Kinh doanh'),
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15)
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Tất cả NVKD'),
                    ),
                    ...state.salesReps.map((salesRep) {
                      return DropdownMenuItem<String>(
                        value: salesRep.id,
                        child: Text(salesRep.displayName ?? salesRep.email ?? 'N/A'),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    context.read<AdminCommissionsCubit>().filterBySalesRep(value);
                  },
                )
              else
                const SizedBox(height: 58, child: Center(child: Text("Đang tải danh sách NVKD..."))),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(startDateText),
                      onPressed: () => _selectDateRange(context, state),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('-'),
                  ),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(endDateText),
                      onPressed: () => _selectDateRange(context, state),
                    ),
                  ),
                  if (state.startDate != null || state.endDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      tooltip: 'Xóa bộ lọc ngày',
                      onPressed: () => context.read<AdminCommissionsCubit>().setDateRange(null),
                    )
                ],
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(value: 'all', label: Text('Tất cả')),
                  ButtonSegment<String>(value: 'pending', label: Text('Chờ xác nhận')),
                  ButtonSegment<String>(value: 'paid', label: Text('Đã xác nhận')),
                ],
                selected: <String>{state.currentFilter},
                onSelectionChanged: (newSelection) {
                  context.read<AdminCommissionsCubit>().filterByStatus(newSelection.first);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommissionCard(BuildContext context, CommissionWithDetails item) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final commission = item.commission;
    final salesRepName = item.salesRepName;
    final isPending = commission.status == CommissionStatus.pending;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đơn hàng: #${commission.orderId.substring(0, 8).toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('NVKD: $salesRepName', style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('Đại lý: ${commission.agentName}'),
            const Divider(),
            _buildInfoRow(context, 'Ngày tạo:', dateFormat.format(commission.createdAt.toDate())),
            _buildInfoRow(context, 'Giá trị ĐH:', currencyFormatter.format(commission.orderTotal)),

            // LƯU Ý: Ở đây code cũ của bạn đang hiển thị tỷ lệ %.
            // Vì logic backend mới tính % linh động (không cố định),
            // bạn nên sửa nhãn hiển thị ở đây để tránh hiểu nhầm.
            // Thay vì: 'Hoa hồng (${(commission.commissionRate * 100).toStringAsFixed(1)}%):'
            // Hãy dùng: 'Hoa hồng thực nhận:'
            _buildInfoRow(context, 'Hoa hồng thực nhận:', currencyFormatter.format(commission.commissionAmount), isBold: true),

            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    isPending ? 'Chờ xác nhận' : 'Đã xác nhận',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: isPending ? Colors.orange.shade700 : Colors.green.shade700,
                ),
                if (isPending)
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Xác nhận Hoa hồng'),
                            content: Text('Bạn có chắc chắn muốn xác nhận khoản hoa hồng ${currencyFormatter.format(commission.commissionAmount)}?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('HỦY')),
                              ElevatedButton(onPressed: (){
                                context.read<AdminCommissionsCubit>().markAsPaid(commission.id);
                                Navigator.of(dialogContext).pop();
                              }, child: const Text('XÁC NHẬN')),
                            ],
                          )
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                    child: const Text('Xác nhận'),
                  )
                else if (commission.paidAt != null)
                  Text('Ngày XN: ${dateFormat.format(commission.paidAt!.toDate())}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}