import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';
import 'package:piv_app/features/vouchers/presentation/bloc/voucher_management_cubit.dart';
import 'package:piv_app/features/vouchers/presentation/pages/voucher_form_page.dart';

class VoucherManagementPage extends StatelessWidget {
  const VoucherManagementPage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const VoucherManagementPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<VoucherManagementCubit>()..loadVouchers(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý Voucher'),
        ),
        body: const VoucherView(),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final bool? result = await Navigator.of(context).push<bool>(VoucherFormPage.route());
            if (result == true && context.mounted) {
              context.read<VoucherManagementCubit>().loadVouchers();
            }
          },
          tooltip: 'Tạo Voucher mới',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class VoucherView extends StatelessWidget {
  const VoucherView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VoucherManagementCubit, VoucherManagementState>(
      builder: (context, state) {
        if (state.status == VoucherStatus.loading && state.vouchers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.vouchers.isEmpty) {
          return const Center(child: Text('Bạn chưa tạo voucher nào.'));
        }
        return RefreshIndicator(
          onRefresh: () => context.read<VoucherManagementCubit>().loadVouchers(),
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: state.vouchers.length,
            itemBuilder: (context, index) {
              final voucher = state.vouchers[index];
              return _buildVoucherCard(context, voucher);
            },
          ),
        );
      },
    );
  }

  Widget _buildVoucherCard(BuildContext context, VoucherModel voucher) {
    final bool isExpired = DateTime.now().isAfter(voucher.expiresAt.toDate());
    final bool isOutOfUses = voucher.maxUses != 0 && voucher.usesCount >= voucher.maxUses;
    final bool isInactive = !voucher.isActive || isExpired || isOutOfUses;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: isInactive ? 0 : 2,
      color: isInactive ? Colors.grey.shade200 : Colors.white,
      child: ListTile(
        title: Text(voucher.id, style: TextStyle(fontWeight: FontWeight.bold, color: isInactive ? Colors.grey.shade600 : Colors.black)),
        subtitle: Text(voucher.description),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              voucher.discountType == DiscountType.percentage
                  ? '${voucher.discountValue.toStringAsFixed(0)}%'
                  : NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(voucher.discountValue),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary),
            ),
            Text('Hạn: ${dateFormat.format(voucher.expiresAt.toDate())}', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}