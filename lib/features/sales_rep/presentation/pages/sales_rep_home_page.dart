import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/commission_model.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/sales_commitment/presentation/bloc/admin/sales_commitment_admin_cubit.dart';
import 'package:piv_app/features/sales_commitment/presentation/pages/admin_commitments_page.dart';
import 'package:piv_app/features/sales_rep/presentation/bloc/sales_rep_commissions_cubit.dart';
import 'package:piv_app/features/sales_rep/presentation/bloc/sales_rep_cubit.dart';
import 'package:piv_app/features/sales_rep/presentation/pages/agent_order_history_page.dart';
import 'package:piv_app/features/sales_rep/presentation/pages/sales_rep_debt_management_page.dart';
import 'package:piv_app/features/vouchers/presentation/bloc/voucher_management_cubit.dart';
import 'package:piv_app/features/vouchers/presentation/pages/voucher_management_page.dart';
import 'package:piv_app/features/sales_rep/agent_approval/bloc/agent_approval_cubit.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:piv_app/features/sales_rep/presentation/pages/create_agent_order_page.dart';
import 'package:piv_app/features/admin/presentation/pages/manage_quick_order_list_page.dart';
import 'package:piv_app/features/notifications/presentation/widgets/notification_icon_with_badge.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_products_cubit.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_products_page.dart';


class SalesRepHomePage extends StatelessWidget {
  const SalesRepHomePage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const SalesRepHomePage());
  }

  @override
  Widget build(BuildContext context) {
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

    // --- SỬA ĐỔI: Tăng length từ 6 lên 7 ---
    return DefaultTabController(
      length: 7, // <-- SỬA Ở ĐÂY
      child: Scaffold(
        appBar: AppBar(
          title: Text('Chào, ${user.displayName ?? user.email}'),
          actions: [
            const NotificationIconWithBadge(),
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
          // --- SỬA ĐỔI: Thêm Tab "Sản phẩm" ---
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: Icon(Icons.people_outline), text: 'Đại lý'),
              Tab(icon: Icon(Icons.account_balance_wallet_outlined), text: 'Công nợ'),
              Tab(icon: Icon(Icons.pending_actions_outlined), text: 'Chờ duyệt'),
              Tab(icon: Icon(Icons.attach_money_outlined), text: 'Hoa hồng'),
              Tab(icon: Icon(Icons.workspace_premium_outlined), text: 'Cam kết'),
              Tab(icon: Icon(Icons.confirmation_number_outlined), text: 'Voucher'),
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Sản phẩm'), // <-- TAB MỚI
            ],
          ),
        ),
        // --- SỬA ĐỔI: Thêm View cho tab "Sản phẩm" ---
        body: const TabBarView(
          children: [
            MyAgentsView(),
            SalesRepDebtManagementPage(),
            PendingAgentsView(),
            SalesRepCommissionsView(),
            CommitmentManagementPageWrapper(),
            VoucherManagementPageWrapper(),
            ProductManagementPageWrapper(),
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

class CommitmentManagementPageWrapper extends StatelessWidget {
  const CommitmentManagementPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<SalesCommitmentAdminCubit>()..watchAllCommitments(),
      child: const AdminCommitmentsPage(),
    );
  }
}

class ProductManagementPageWrapper extends StatelessWidget {
  const ProductManagementPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AdminProductsCubit>()..fetchAllProducts(),
      child: const AdminProductsPage(),
    );
  }
}

class VoucherManagementPageWrapper extends StatelessWidget {
  const VoucherManagementPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<VoucherManagementCubit>()..getVouchers(),
      child: const VoucherManagementPage(),
    );
  }
}

class MyAgentsView extends StatelessWidget {
  const MyAgentsView({super.key});

  (Color, String) _getStatusInfo(String status, BuildContext context) {
    switch (status) {
      case 'active': return (Theme.of(context).colorScheme.primary, 'Hoạt động');
      case 'suspended': return (Colors.red.shade700, 'Bị khóa');
      default: return (Colors.grey.shade700, 'Không xác định');
    }
  }

  String _getAgentRoleText(String role) {
    switch (role) {
      case 'agent_1': return 'Đại lý Cấp 1';
      case 'agent_2': return 'Đại lý Cấp 2';
      default: return 'Chưa phân loại';
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
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: state.myAgents.length,
            itemBuilder: (context, index) {
              final agent = state.myAgents[index];
              final statusInfo = _getStatusInfo(agent.status, context);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  isThreeLine: true,
                  title: Text(agent.displayName ?? 'Chưa có tên', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(agent.email ?? 'Không có email'),
                      const SizedBox(height: 4),
                      Text(
                        _getAgentRoleText(agent.role),
                        style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'view_history') {
                        Navigator.of(context).push(AgentOrderHistoryPage.route(
                          agentId: agent.id,
                          agentName: agent.displayName ?? 'N/A',
                        ));
                      } else if (value == 'place_order') {
                        Navigator.of(context).push(CreateAgentOrderPage.route(agent));
                      }
                      // <<< THÊM LOGIC MỚI >>>
                      else if (value == 'manage_quick_order') {
                        Navigator.of(context).push(ManageQuickOrderListPage.route(agent));
                      }
                    },
                    // <<< THÊM ITEM MỚI VÀO MENU >>>
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'view_history',
                        child: ListTile(leading: Icon(Icons.history), title: Text('Xem lịch sử')),
                      ),
                      const PopupMenuItem<String>(
                        value: 'place_order',
                        child: ListTile(leading: Icon(Icons.add_shopping_cart), title: Text('Đặt hàng hộ')),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'manage_quick_order',
                        child: ListTile(leading: Icon(Icons.playlist_add_check), title: Text('Quản lý Đặt nhanh')),
                      ),
                    ],
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

class PendingAgentsView extends StatelessWidget {
  const PendingAgentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AgentApprovalCubit>()..fetchUnassignedAgents(),
      child: BlocConsumer<AgentApprovalCubit, AgentApprovalState>(
        listener: (context, state) {
          if (state is AgentApprovalFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
          if (state is AgentApprovalSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Duyệt đại lý thành công!'), backgroundColor: Colors.green));
            context.read<SalesRepCubit>().fetchMyAgents();
          }
        },
        builder: (context, state) {
          if (state is AgentApprovalLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AgentApprovalLoaded) {
            if (state.users.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async => context.read<AgentApprovalCubit>().fetchUnassignedAgents(),
                child: const CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      child: Center(
                        child: Text('Không có đại lý nào đang chờ duyệt.'),
                      ),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => context.read<AgentApprovalCubit>().fetchUnassignedAgents(),
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
          return const Center(child: Text('Đang tải dữ liệu...'));
        },
      ),
    );
  }

  Widget _buildAgentCard(BuildContext context, UserModel agent) {
    final agentName = agent.displayName ?? 'Đại lý chưa có tên';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(agentName.isNotEmpty ? agentName[0].toUpperCase() : 'A'),
        ),
        title: Text(agentName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(agent.email ?? 'Chưa có thông tin liên hệ'),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
          ),
          onPressed: () => _showApprovalOptionsDialog(context, agent),
          child: const Text('Duyệt'),
        ),
      ),
    );
  }


  void _showApprovalOptionsDialog(BuildContext context, UserModel agent) {
    final agentName = agent.displayName ?? 'Đại lý chưa có tên';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Duyệt Đại lý "$agentName"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Vui lòng chọn cấp bậc cho đại lý này:'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.star_rounded),
              label: const Text('Duyệt thành Đại lý Cấp 1'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                context.read<AgentApprovalCubit>().approveAgent(agent.id, 'agent_1');
                Navigator.of(ctx).pop();
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.star_half_rounded),
              label: const Text('Duyệt thành Đại lý Cấp 2'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                context.read<AgentApprovalCubit>().approveAgent(agent.id, 'agent_2');
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('HỦY BỎ'),
          ),
        ],
      ),
    );
  }
}

class SalesRepCommissionsView extends StatelessWidget {
  const SalesRepCommissionsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Nội dung gốc của màn hình hoa hồng
    final originalContent = Column(
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

    // Sử dụng Stack để chồng lớp phủ lên trên nội dung gốc
    return Stack(
      children: [
        // Lớp 1: Nội dung gốc
        originalContent,

        // Lớp 2: Lớp kính mờ
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
            child: Container(
              color: Colors.black.withOpacity(0.1),
            ),
          ),
        ),

        // Lớp 3: Lớp thông báo
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Tính năng này tạm thời chưa được áp dụng',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Các hàm helper bên dưới được giữ nguyên để không gây lỗi biên dịch,
  // mặc dù chúng sẽ bị lớp phủ che đi.
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