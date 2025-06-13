import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_users_cubit.dart';
import 'package:piv_app/data/models/user_model.dart';

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const AdminUsersPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdminUsersCubit>()..fetchAllUsers(),
      child: const AdminUsersView(),
    );
  }
}

class AdminUsersView extends StatelessWidget {
  const AdminUsersView({super.key});

  // Hàm helper để lấy màu và text cho trạng thái
  (Color, String) _getStatusInfo(String status, BuildContext context) {
    switch (status) {
      case 'pending_approval':
        return (Colors.orange.shade700, 'Chờ duyệt');
      case 'active':
        return (Theme.of(context).colorScheme.primary, 'Hoạt động');
      case 'suspended':
        return (Colors.red.shade700, 'Bị khóa');
      default:
        return (Colors.grey.shade700, 'Không xác định');
    }
  }

  // Hàm helper để lấy tên vai trò tiếng Việt
  String _getRoleName(String role) {
    switch (role) {
      case 'admin':
        return 'Quản trị viên';
      case 'agent_1':
        return 'Đại lý cấp 1';
      case 'agent_2':
        return 'Đại lý cấp 2';
      default:
        return 'Chưa phân loại';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Người dùng'),
      ),
      body: Column(
        children: [
          // Bộ lọc người dùng
          BlocBuilder<AdminUsersCubit, AdminUsersState>(
            buildWhen: (previous, current) => previous.currentFilter != current.currentFilter,
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
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
          // Danh sách người dùng
          Expanded(
            child: BlocBuilder<AdminUsersCubit, AdminUsersState>(
              builder: (context, state) {
                if (state.status == AdminUsersStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == AdminUsersStatus.error) {
                  return Center(child: Text(state.errorMessage ?? 'Lỗi tải dữ liệu'));
                }
                if (state.filteredUsers.isEmpty) {
                  return Center(child: Text('Không có người dùng nào khớp với bộ lọc.'));
                }

                return RefreshIndicator(
                  onRefresh: () async => context.read<AdminUsersCubit>().fetchAllUsers(),
                  child: ListView.separated(
                    itemCount: state.filteredUsers.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
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
                              decoration: BoxDecoration(
                                color: statusInfo.$1.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusInfo.$2,
                                style: TextStyle(color: statusInfo.$1, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                        onTap: () {
                          _showEditUserDialog(context, user);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Hàm hiển thị dialog để sửa vai trò và trạng thái
  void _showEditUserDialog(BuildContext parentContext, UserModel user) {
    final cubit = parentContext.read<AdminUsersCubit>();
    String selectedRole = user.role;
    String selectedStatus = user.status;

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        // Sử dụng StatefulWidget để quản lý trạng thái của các DropdownButton
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
                      items: [
                        const DropdownMenuItem(value: 'agent_1', child: Text('Đại lý cấp 1')),
                        const DropdownMenuItem(value: 'agent_2', child: Text('Đại lý cấp 2')),
                        const DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
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
                      items: [
                        const DropdownMenuItem(value: 'pending_approval', child: Text('Chờ duyệt')),
                        const DropdownMenuItem(value: 'active', child: Text('Hoạt động')),
                        const DropdownMenuItem(value: 'suspended', child: Text('Bị khóa')),
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
