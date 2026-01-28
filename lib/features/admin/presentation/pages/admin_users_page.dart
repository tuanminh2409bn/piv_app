// lib/features/admin/presentation/pages/admin_users_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_users_cubit.dart';
import 'package:piv_app/features/admin/presentation/pages/sales_rep_agents_page.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/admin/presentation/pages/agent_discount_config_page.dart';
import 'package:piv_app/features/admin/presentation/pages/agent_special_price_page.dart';

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdminUsersCubit>()..fetchAndGroupUsers(),
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Quản lý Người dùng'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Tải lại',
                onPressed: () =>
                    context.read<AdminUsersCubit>().fetchAndGroupUsers(),
              ),
            ],
          ),
          body: const AdminUsersView(),
        );
      }),
    );
  }
}

class AdminUsersView extends StatelessWidget {
  const AdminUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUser =
    (authState is AuthAuthenticated) ? authState.user : null;

    return BlocBuilder<AdminUsersCubit, AdminUsersState>(
      builder: (context, state) {
        if (state.status == AdminUsersStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == AdminUsersStatus.error) {
          return Center(child: Text(state.errorMessage ?? 'Có lỗi xảy ra'));
        }

        final admins = state.allUsers.where((user) => user.role == 'admin').toList();
        final accountants = state.allUsers.where((user) => user.role == 'accountant').toList();
        final bool isAdmin = currentUser?.role == 'admin';

        return RefreshIndicator(
          onRefresh: () => context.read<AdminUsersCubit>().fetchAndGroupUsers(),
          child: ListView(
            padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0 + MediaQuery.of(context).padding.bottom),
            children: [
              _buildSectionHeader(context, 'Nhân viên Kinh doanh',
                  Icons.support_agent_rounded,
                  count: state.salesRepsWithAgentCount.length),
              _buildSalesRepsList(context, state.salesRepsWithAgentCount,
                  currentUser?.id ?? ''),
              const SizedBox(height: 16),

              if (isAdmin) ...[
                _buildSectionHeader(context, 'Kế toán',
                    Icons.account_balance_wallet_outlined,
                    count: accountants.length),
                _buildAccountantsList(context, accountants, currentUser?.id ?? ''),
                const SizedBox(height: 16),
              ],

              _buildSectionHeader(context, 'Đại lý chờ duyệt & chưa gán',
                  Icons.person_add_disabled_outlined,
                  count: state.unassignedAgents.length),
              _buildUnassignedAgentsList(
                  context, state.unassignedAgents, currentUser?.id ?? ''),
              const SizedBox(height: 16),

              if (isAdmin) ...[
                _buildSectionHeader(context, 'Quản trị viên',
                    Icons.admin_panel_settings_outlined,
                    count: admins.length),
                _buildAdminsList(context, admins, currentUser?.id ?? ''),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, {required int count}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Chip(label: Text('$count')),
        ],
      ),
    );
  }

  Widget _buildSalesRepsList(BuildContext context, List<SalesRepWithAgentCount> salesReps, String currentAdminId) {
    if (salesReps.isEmpty) return const _EmptyStateCard(message: 'Chưa có Nhân viên Kinh doanh nào.');
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: salesReps.length,
      itemBuilder: (context, index) {
        final item = salesReps[index];
        final salesRep = item.$1;
        final agentCount = item.$2;
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(salesRep.displayName?[0].toUpperCase() ?? 'N')),
            title: Text(salesRep.displayName ?? 'Chưa có tên', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(salesRep.email ?? 'Chưa có email'),
            trailing: Chip(
              label: Text('$agentCount Đại lý'),
              avatar: const Icon(Icons.people_alt_outlined, size: 16),
            ),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<AdminUsersCubit>(),
                  child: SalesRepAgentsPage(salesRep: salesRep),
                ),
              ));
            },
            onLongPress: () => _showEditUserDialog(context, salesRep),
          ),
        );
      },
    );
  }

  Widget _buildUnassignedAgentsList(BuildContext context, List<UserModel> agents, String currentAdminId) {
    if (agents.isEmpty) return const _EmptyStateCard(message: 'Tất cả đại lý đã có người phụ trách.');
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: agents.length,
      itemBuilder: (context, index) {
        final agent = agents[index];
        final isActive = agent.status == 'active';

        return Card(
          color: Colors.orange.shade50,
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.orange.shade100, child: const Icon(Icons.person_outline, color: Colors.orange)),
            title: Text(agent.displayName ?? 'Chưa có tên'),
            subtitle: Text(agent.email ?? 'Chưa có email'),
            trailing: isActive
                ? IconButton(
                    icon: const Icon(Icons.price_change_outlined, color: Colors.blue),
                    tooltip: 'Cấu hình chiết khấu riêng',
                    onPressed: () {
                      Navigator.of(context).push(AgentDiscountConfigPage.route(
                        user: agent,
                        cubit: context.read<AdminUsersCubit>(),
                      ));
                    },
                  )
                : null,
            onTap: () => _showEditUserDialog(context, agent),
          ),
        );
      },
    );
  }

  Widget _buildAdminsList(BuildContext context, List<UserModel> admins, String currentAdminId) {
    if (admins.isEmpty) return const _EmptyStateCard(message: 'Chưa có Quản trị viên nào.');
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: admins.length,
      itemBuilder: (context, index) {
        final admin = admins[index];
        final isSelf = admin.id == currentAdminId;

        return Card(
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: const Icon(Icons.security, color: Colors.blue)),
            title: Text(admin.displayName ?? 'Chưa có tên'),
            subtitle: Text(admin.email ?? 'Chưa có email'),
            trailing: isSelf ? const Chip(label: Text('BẠN')) : null,
            onTap: () {
              if (isSelf) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bạn không thể tự sửa vai trò và trạng thái của chính mình.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } else {
                _showEditUserDialog(context, admin);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildAccountantsList(BuildContext context, List<UserModel> accountants, String currentUserId) {
    if (accountants.isEmpty) return const _EmptyStateCard(message: 'Chưa có Kế toán nào.');
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: accountants.length,
      itemBuilder: (context, index) {
        final accountant = accountants[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.purple.shade50, child: const Icon(Icons.receipt_long, color: Colors.purple)),
            title: Text(accountant.displayName ?? 'Chưa có tên', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(accountant.email ?? 'Chưa có email'),
            onTap: () => _showEditUserDialog(context, accountant),
          ),
        );
      },
    );
  }

  void _showEditUserDialog(BuildContext parentContext, UserModel userToEdit) {
    final cubit = parentContext.read<AdminUsersCubit>();
    final currentUser = (parentContext.read<AuthBloc>().state as AuthAuthenticated).user;

    String selectedRole = userToEdit.role;
    String selectedStatus = userToEdit.status;

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final availableRoles = _getAvailableRolesForUser(currentUser.role);

            return AlertDialog(
              title: const Text('Cập nhật người dùng'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userToEdit.displayName ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(userToEdit.email ?? ''),
                    const Divider(height: 24),
                    const Text('Vai trò', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: availableRoles.any((item) => item.value == selectedRole) ? selectedRole : null,
                      isExpanded: true,
                      hint: const Text('Không có quyền thay đổi vai trò'),
                      items: availableRoles,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedRole = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: selectedStatus,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'pending_approval', child: Text('Chờ duyệt')),
                        DropdownMenuItem(value: 'active', child: Text('Hoạt động')),
                        DropdownMenuItem(value: 'suspended', child: Text('Bị khóa')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedStatus = value);
                        }
                      },
                    ),
                    // Chỉ hiển thị nút cấu hình nếu là đại lý VÀ đã active
                    if ((userToEdit.role == 'agent_1' || userToEdit.role == 'agent_2') && userToEdit.status == 'active') ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.percent),
                          label: const Text('Cấu hình Chiết khấu (Tổng đơn)'),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            Navigator.of(parentContext).push(AgentDiscountConfigPage.route(
                              user: userToEdit,
                              cubit: cubit,
                            ));
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.price_change),
                          label: const Text('Cấu hình Bảng giá Riêng (Sản phẩm)'),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            Navigator.of(parentContext).push(AgentSpecialPricePage.route(
                              user: userToEdit,
                            ));
                          },
                        ),
                      ),
                    ],
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
                    cubit.updateUser(userToEdit.id, selectedRole, selectedStatus);
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<DropdownMenuItem<String>> _getAvailableRolesForUser(String currentUserRole) {
    const allRoles = {
      'accountant': 'Kế toán',
      'sales_rep': 'Nhân viên Kinh doanh',
      'agent_1': 'Đại lý cấp 1',
      'agent_2': 'Đại lý cấp 2',
      'admin': 'Quản trị viên',
    };

    List<String> allowedRoleKeys = [];

    if (currentUserRole == 'admin') {
      allowedRoleKeys = ['accountant', 'sales_rep', 'agent_1', 'agent_2', 'admin'];
    } else if (currentUserRole == 'accountant') {
      allowedRoleKeys = ['sales_rep', 'agent_1', 'agent_2'];
    }

    return allowedRoleKeys
        .map((key) => DropdownMenuItem(value: key, child: Text(allRoles[key]!)))
        .toList();
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(child: Text(message, style: TextStyle(color: Colors.grey.shade700))),
      ),
    );
  }
}
