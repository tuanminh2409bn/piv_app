import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/commission_model.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/sales_rep/presentation/bloc/sales_rep_commissions_cubit.dart';
import 'package:piv_app/features/sales_rep/presentation/bloc/sales_rep_cubit.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SalesRepHomePage extends StatelessWidget {
  const SalesRepHomePage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const SalesRepHomePage());
  }

  @override
  Widget build(BuildContext context) {
    // Cung cấp các Cubit cần thiết cho các tab
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<SalesRepCubit>()..fetchMyAgents()),
        BlocProvider(create: (_) => sl<SalesRepCommissionsCubit>()..fetchMyCommissions()),
      ],
      child: const SalesRepView(),
    );
  }
}

class SalesRepView extends StatelessWidget {
  const SalesRepView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Chào, ${user.displayName ?? user.email}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_2_outlined),
              tooltip: 'Mã QR Giới thiệu',
              onPressed: () => _showReferralQrDialog(context, user),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Đăng xuất',
              onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people_outline), text: 'Đại lý của tôi'),
              Tab(icon: Icon(Icons.attach_money_outlined), text: 'Hoa hồng'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MyAgentsView(),
            SalesRepCommissionsView(),
          ],
        ),
      ),
    );
  }

  // Hàm để hiển thị dialog chứa mã QR
  void _showReferralQrDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Mã QR Giới thiệu của bạn'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Đưa mã này cho đại lý mới để quét từ trong ứng dụng của họ.'),
                const SizedBox(height: 20),
                Center(
                  child: QrImageView(
                    data: user.id, // Dữ liệu của mã QR chính là ID của NVKD
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Hoặc cung cấp mã:'),
                SelectableText(
                  user.id,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ĐÓNG'),
            )
          ],
        );
      },
    );
  }
}

// =================================================================
//                     VIEW DANH SÁCH ĐẠI LÝ
// =================================================================
class MyAgentsView extends StatelessWidget {
  const MyAgentsView({super.key});

  (Color, String) _getStatusInfo(String status, BuildContext context) {
    switch (status) {
      case 'pending_approval': return (Colors.orange.shade700, 'Chờ duyệt');
      case 'active': return (Theme.of(context).colorScheme.primary, 'Hoạt động');
      case 'suspended': return (Colors.red.shade700, 'Bị khóa');
      default: return (Colors.grey.shade700, 'Không xác định');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => context.read<SalesRepCubit>().fetchMyAgents(),
      child: BlocBuilder<SalesRepCubit, SalesRepState>(
        builder: (context, state) {
          if (state.status == SalesRepStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.myAgents.isEmpty) {
            return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Bạn chưa có đại lý nào được ghi nhận. Hãy dùng mã QR để giới thiệu!', textAlign: TextAlign.center),
                ));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(8.0),
            itemCount: state.myAgents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 0),
            itemBuilder: (context, index) {
              final agent = state.myAgents[index];
              final statusInfo = _getStatusInfo(agent.status, context);
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  title: Text(agent.displayName ?? 'Chưa có tên', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(agent.email ?? 'Không có email'),
                  trailing: Chip(
                    label: Text(statusInfo.$2, style: const TextStyle(fontSize: 12)),
                    backgroundColor: statusInfo.$1.withOpacity(0.2),
                    side: BorderSide.none,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =================================================================
//                     VIEW HOA HỒNG CỦA NVKD
// =================================================================
class SalesRepCommissionsView extends StatelessWidget {
  const SalesRepCommissionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => context.read<SalesRepCommissionsCubit>().fetchMyCommissions(),
      child: BlocBuilder<SalesRepCommissionsCubit, SalesRepCommissionsState>(
        builder: (context, state) {
          if (state.status == SalesRepCommissionsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.commissions.isEmpty) {
            return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Bạn chưa có hoa hồng nào. Hoa hồng sẽ được tạo khi đơn hàng của đại lý được xác nhận hoàn thành.', textAlign: TextAlign.center),
                ));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: state.commissions.length,
            itemBuilder: (context, index) {
              final commission = state.commissions[index];
              return _buildCommissionCard(context, commission);
            },
          );
        },
      ),
    );
  }

  Widget _buildCommissionCard(BuildContext context, CommissionModel commission) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isPending = commission.status == CommissionStatus.pending;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Từ ĐH #${commission.orderId.substring(0, 8)} của ${commission.agentName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            _buildInfoRow(context, 'Ngày tạo:', dateFormat.format(commission.createdAt.toDate())),
            _buildInfoRow(context, 'Giá trị ĐH:', currencyFormatter.format(commission.orderTotal)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hoa hồng của bạn:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  currencyFormatter.format(commission.commissionAmount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Chip(
                label: Text(
                  isPending ? 'Chờ xác nhận' : 'Đã xác nhận',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: isPending ? Colors.orange.shade700 : Colors.green.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}