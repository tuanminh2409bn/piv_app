import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_users_cubit.dart';
import 'package:piv_app/features/admin/presentation/pages/agent_discount_config_page.dart';
import 'package:piv_app/features/admin/presentation/pages/agent_special_price_page.dart';

class SalesRepAgentsPage extends StatelessWidget {
  final UserModel salesRep;

  const SalesRepAgentsPage({super.key, required this.salesRep});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đại lý của ${salesRep.displayName ?? ''}'),
      ),
      body: BlocBuilder<AdminUsersCubit, AdminUsersState>(
        builder: (context, state) {
          final agents = state.allUsers.where((user) => user.salesRepId == salesRep.id).toList();

          if (agents.isEmpty) {
            return const Center(child: Text('NVKD này chưa có đại lý nào.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: agents.length,
            itemBuilder: (context, index) {
              final agent = agents[index];
              final isActive = agent.status == 'active';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(child: Text(agent.displayName?[0].toUpperCase() ?? 'Đ')),
                  title: Text(agent.displayName ?? 'Chưa có tên', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Cấp: ${agent.role.replaceAll('agent_', '')} - Trạng thái: ${agent.status}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.price_change_outlined, color: Colors.blue),
                    tooltip: 'Cấu hình chiết khấu riêng',
                    onPressed: () {
                      Navigator.of(context).push(AgentDiscountConfigPage.route(
                        user: agent,
                      ));
                    },
                  ),
                  onTap: () => _showEditUserDialog(context, agent),
                ),
              );
            },
          );
        },
      ),
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
                    // Chỉ hiển thị nút cấu hình nếu là đại lý
                    if (user.role == 'agent_1' || user.role == 'agent_2') ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.percent),
                          label: const Text('Cấu hình Chiết khấu (Tổng đơn)'),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            Navigator.of(parentContext).push(AgentDiscountConfigPage.route(
                              user: user,
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
                              user: user,
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