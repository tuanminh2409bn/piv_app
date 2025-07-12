// lib/features/admin/presentation/pages/admin_users_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_users_cubit.dart';

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdminUsersCubit>()..fetchAllUsers(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý Người dùng'),
        ),
        body: const AdminUsersView(),
      ),
    );
  }
}

class AdminUsersView extends StatelessWidget {
  const AdminUsersView({super.key});

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
    return Column(
      children: [
        BlocBuilder<AdminUsersCubit, AdminUsersState>(
          buildWhen: (previous, current) => previous.currentFilter != current.currentFilter,
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(value: 'all', label: Text('Tất cả')),
                  ButtonSegment<String>(value: 'pending_approval', label: Text('Chờ duyệt')),
                  ButtonSegment<String>(value: 'active', label: Text('Hoạt động')),
                ],
                selected: <String>{state.currentFilter},
                onSelectionChanged: (Set<String> newSelection) {
                  context.read<AdminUsersCubit>().filterUsers(newSelection.first);
                },
              ),
            );
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: BlocBuilder<AdminUsersCubit, AdminUsersState>(
            builder: (context, state) {
              if (state.status == AdminUsersStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.filteredUsers.isEmpty) {
                return const Center(child: Text('Không có người dùng nào.'));
              }

              return RefreshIndicator(
                onRefresh: () async => context.read<AdminUsersCubit>().fetchAllUsers(),
                child: ListView.separated(
                  itemCount: state.filteredUsers.length,
                  separatorBuilder: (_, __) => const Divider(height: 0, indent: 16),
                  itemBuilder: (context, index) {
                    final user = state.filteredUsers[index];
                    final statusInfo = _getStatusInfo(user.status, context);
                    return ListTile(
                      title: Text(user.displayName ?? 'Chưa có tên', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(user.email ?? 'Không có email'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: statusInfo.$1.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                            child: Text(statusInfo.$2, style: TextStyle(color: statusInfo.$1, fontSize: 12, fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ],
                      ),
                      onTap: () => _showEditUserDialog(context, user),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

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