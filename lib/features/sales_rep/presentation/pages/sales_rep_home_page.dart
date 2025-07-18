import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/commission_model.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/sales_rep/presentation/bloc/sales_rep_commissions_cubit.dart';
import 'package:piv_app/features/sales_rep/presentation/bloc/sales_rep_cubit.dart';
import 'package:piv_app/features/sales_rep/presentation/pages/agent_order_history_page.dart';
import 'package:piv_app/features/vouchers/presentation/bloc/voucher_management_cubit.dart';
import 'package:piv_app/features/vouchers/presentation/pages/voucher_management_page.dart';
import 'package:piv_app/features/sales_rep/agent_approval/bloc/agent_approval_cubit.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SalesRepHomePage extends StatelessWidget {
  const SalesRepHomePage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const SalesRepHomePage());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<SalesRepCubit>()),
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
      length: 4,
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
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: Icon(Icons.people_outline), text: 'Đại lý'),
              Tab(icon: Icon(Icons.pending_actions_outlined), text: 'Chờ duyệt'),
              Tab(icon: Icon(Icons.attach_money_outlined), text: 'Hoa hồng'),
              Tab(icon: Icon(Icons.confirmation_number_outlined), text: 'Voucher'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const MyAgentsView(),
            const PendingAgentsView(),
            const SalesRepCommissionsView(),
            BlocProvider(
              create: (context) => sl<VoucherManagementCubit>()..getVouchers(),
              child: const VoucherManagementPage(),
            ),
          ],
        ),
      ),
    );
  }

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
                    data: user.id,
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
//                     VIEW DANH SÁCH ĐẠI LÝ ĐÃ DUYỆT
// =================================================================
class MyAgentsView extends StatelessWidget {
  const MyAgentsView({super.key});

  (Color, String) _getStatusInfo(String status, BuildContext context) {
    switch (status) {
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
          if (state.status == SalesRepStatus.loading && state.myAgents.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.myAgents.isEmpty) {
            return const Center(child: Text('Bạn chưa có đại lý nào.'));
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
                  onTap: () {
                    Navigator.of(context).push(AgentOrderHistoryPage.route(
                      agentId: agent.id,
                      agentName: agent.displayName ?? 'N/A',
                    ));
                  },
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
//                 VIEW ĐẠI LÝ CHỜ DUYỆT
// =================================================================
class PendingAgentsView extends StatelessWidget {
  const PendingAgentsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Sử dụng BlocProvider để cung cấp AgentApprovalCubit cho riêng tab này
    return BlocProvider(
      create: (context) => sl<AgentApprovalCubit>()..fetchUnassignedAgents(),
      child: BlocConsumer<AgentApprovalCubit, AgentApprovalState>(
        listener: (context, state) {
          // Hiển thị SnackBar khi có lỗi
          if (state is AgentApprovalFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
          }
        },
        builder: (context, state) {
          if (state is AgentApprovalLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AgentApprovalLoaded) {
            if (state.users.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Tuyệt vời! Không có đại lý nào đang chờ bạn duyệt.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              );
            }
            // Thêm RefreshIndicator để người dùng có thể vuốt xuống để tải lại
            return RefreshIndicator(
              onRefresh: () async {
                context.read<AgentApprovalCubit>().fetchUnassignedAgents();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: state.users.length,
                itemBuilder: (context, index) {
                  final agent = state.users[index];
                  return _buildAgentCard(context, agent);
                },
              ),
            );
          }
          // Trạng thái ban đầu hoặc có lỗi cũng sẽ hiển thị thông báo
          return const Center(child: Text('Đang tải dữ liệu...'));
        },
      ),
    );
  }

  // Widget con để hiển thị thông tin đại lý
  Widget _buildAgentCard(BuildContext context, UserModel agent) {
    // ‼️ SỬA LỖI TẠI ĐÂY: Dùng `displayName` thay vì `fullName`
    final agentName = agent.displayName ?? 'Đại lý chưa có tên';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Text(agentName.isNotEmpty ? agentName[0].toUpperCase() : 'A'),
        ),
        title: Text(agentName, style: const TextStyle(fontWeight: FontWeight.bold)),
        // ‼️ SỬA LỖI TẠI ĐÂY: Dùng `email` thay vì `phoneNumber`
        subtitle: Text(agent.email ?? 'Chưa có thông tin liên hệ'),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => _showConfirmationDialog(context, agent),
          child: const Text('Duyệt'),
        ),
      ),
    );
  }

  // Dialog xác nhận duyệt
  void _showConfirmationDialog(BuildContext context, UserModel agent) {
    // ‼️ SỬA LỖI TẠI ĐÂY: Dùng `displayName`
    final agentName = agent.displayName ?? 'Đại lý chưa có tên';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác Nhận Duyệt'),
        content: Text('Bạn có chắc chắn muốn duyệt và quản lý đại lý "$agentName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              // Gọi hàm approveAgent từ AgentApprovalCubit
              context.read<AgentApprovalCubit>().approveAgent(agent.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Duyệt'),
          ),
        ],
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
    return Column(
      children: [
        _buildFilters(context),
        const Divider(height: 1),
        _buildSummary(context),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => context.read<SalesRepCommissionsCubit>().fetchMyCommissions(),
            child: BlocBuilder<SalesRepCommissionsCubit, SalesRepCommissionsState>(
              builder: (context, state) {
                if (state.status == SalesRepCommissionsStatus.loading && state.commissions.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.commissions.isEmpty) {
                  return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Không có hoa hồng nào trong khoảng thời gian đã chọn.', textAlign: TextAlign.center),
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
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: BlocBuilder<SalesRepCommissionsCubit, SalesRepCommissionsState>(
        builder: (context, state) {
          final dateFormat = DateFormat('dd/MM/yyyy');
          final startDateText = state.startDate != null ? dateFormat.format(state.startDate!) : 'Từ ngày';
          final endDateText = state.endDate != null ? dateFormat.format(state.endDate!) : 'Đến ngày';

          return Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  child: Text(startDateText),
                  onPressed: () => _selectDateRange(context, state),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('-'),
              ),
              Expanded(
                child: OutlinedButton(
                  child: Text(endDateText),
                  onPressed: () => _selectDateRange(context, state),
                ),
              ),
              if (state.startDate != null || state.endDate != null)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.red),
                  onPressed: () => context.read<SalesRepCommissionsCubit>().setDateRange(null),
                )
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return BlocBuilder<SalesRepCommissionsCubit, SalesRepCommissionsState>(
        builder: (context, state) {
          final totalCommission = state.commissions.fold<double>(0.0, (sum, item) => sum + item.commissionAmount);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tổng cộng:', style: Theme.of(context).textTheme.titleMedium),
                Text(
                    currencyFormatter.format(totalCommission),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)
                ),
              ],
            ),
          );
        }
    );
  }

  Future<void> _selectDateRange(BuildContext context, SalesRepCommissionsState state) async {
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
      context.read<SalesRepCommissionsCubit>().setDateRange(newDateRange);
    }
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
