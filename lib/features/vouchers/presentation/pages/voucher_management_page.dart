import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';
import 'package:piv_app/features/vouchers/presentation/bloc/voucher_management_cubit.dart';
import 'package:piv_app/features/vouchers/presentation/pages/voucher_form_page.dart';

class VoucherManagementPage extends StatelessWidget {
  const VoucherManagementPage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (context) => sl<VoucherManagementCubit>()..getVouchers(),
        child: const VoucherManagementPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const VoucherManagementView();
  }
}

class VoucherManagementView extends StatelessWidget {
  const VoucherManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Voucher')),
      body: BlocBuilder<VoucherManagementCubit, VoucherManagementState>(
        builder: (context, state) {
          if (state.status == VoucherManagementStatus.loading && state.vouchers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == VoucherManagementStatus.error) {
            return Center(child: Text(state.errorMessage ?? 'Lỗi tải dữ liệu'));
          }
          if (state.vouchers.isEmpty) {
            return const Center(child: Text('Bạn chưa tạo voucher nào.'));
          }

          return ListView.builder(
            itemCount: state.vouchers.length,
            itemBuilder: (context, index) {
              final voucher = state.vouchers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(voucher.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(voucher.description),
                  trailing: _buildStatusChip(voucher.status),
                  onTap: () {
                    // Bọc VoucherFormPage trong BlocProvider.value để nó có thể truy cập cubit
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: BlocProvider.of<VoucherManagementCubit>(context),
                          child: VoucherFormPage(voucher: voucher),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: BlocProvider.of<VoucherManagementCubit>(context),
                child: const VoucherFormPage(),
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    switch (status) {
      case VoucherStatus.active:
        color = Colors.green;
        text = 'Hoạt động';
        break;
      case VoucherStatus.pendingApproval:
        color = Colors.orange;
        text = 'Chờ duyệt';
        break;
      case VoucherStatus.pendingDeletion:
        color = Colors.red;
        text = 'Chờ xóa';
        break;
      case VoucherStatus.rejected:
        color = Colors.grey;
        text = 'Bị từ chối';
        break;
      default:
        color = Colors.grey.shade400;
        text = 'Không hoạt động';
    }
    return Chip(
      label: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      labelPadding: EdgeInsets.zero,
    );
  }
}