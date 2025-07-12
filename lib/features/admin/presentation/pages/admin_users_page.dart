import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_users_cubit.dart';
import 'package:piv_app/features/admin/presentation/pages/sales_rep_agents_page.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdminUsersCubit>()..fetchAndGroupUsers(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý Người dùng'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Tải lại',
              onPressed: () => context.read<AdminUsersCubit>().fetchAndGroupUsers(),
            ),
          ],
        ),
        body: const AdminUsersView(),
      ),
    );
  }
}

class AdminUsersView extends StatelessWidget {
  const AdminUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy ID của Admin đang đăng nhập
    final authState = context.watch<AuthBloc>().state;
    final currentAdminId = (authState is AuthAuthenticated) ? authState.user.id : '';

    return BlocBuilder<AdminUsersCubit, AdminUsersState>(
      builder: (context, state) {
        if (state.status == AdminUsersStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == AdminUsersStatus.error) {
          return Center(child: Text(state.errorMessage ?? 'Có lỗi xảy ra'));
        }

        return RefreshIndicator(
          onRefresh: () => context.read<AdminUsersCubit>().fetchAndGroupUsers(),
          child: ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              _buildSectionHeader(context, 'Nhân viên Kinh doanh', Icons.support_agent_rounded, count: state.salesReps.length),
              _buildSalesRepsList(context, state.salesReps, currentAdminId),
              const SizedBox(height: 16),
              _buildSectionHeader(context, 'Đại lý chưa có người phụ trách', Icons.person_add_disabled_outlined, count: state.unassignedAgents.length),
              _buildUnassignedAgentsList(context, state.unassignedAgents, currentAdminId),
              const SizedBox(height: 16),
              _buildSectionHeader(context, 'Quản trị viên', Icons.admin_panel_settings_outlined, count: state.admins.length),
              _buildAdminsList(context, state.admins, currentAdminId),
            ],
          ),
        );
      },
    );
  }

  // --- CÁC HÀM HELPER ĐỂ DỰNG GIAO DIỆN ---

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
                builder: (_) => SalesRepAgentsPage(salesRep: salesRep),
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
        return Card(
          color: Colors.orange.shade50,
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.orange.shade100, child: const Icon(Icons.person_outline, color: Colors.orange)),
            title: Text(agent.displayName ?? 'Chưa có tên'),
            subtitle: Text(agent.email ?? 'Chưa có email'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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

  // ‼️ HÀM HELPER ĐÃ ĐƯỢC BỔ SUNG ĐẦY ĐỦ ‼️
  void _showEditUserDialog(BuildContext parentContext, UserModel user) {
    final cubit = parentContext.read<AdminUsersCubit>();
    String selectedRole = user.role;
    String selectedStatus = user.status;

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Cập nhật người dùng'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(user.email ?? ''),
                    const Divider(height: 24),
                    const Text('Vai trò', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: selectedRole,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'agent_1', child: Text('Đại lý cấp 1')),
                        DropdownMenuItem(value: 'agent_2', child: Text('Đại lý cấp 2')),
                        DropdownMenuItem(value: 'sales_rep', child: Text('Nhân viên Kinh doanh')),
                        DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
                      ],
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
                    cubit.updateUser(user.id, selectedRole, selectedStatus);
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
}

// ‼️ CLASS _EmptyStateCard ĐÃ ĐƯỢC ĐỊNH NGHĨA ĐÚNG ‼️
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