import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_users_cubit.dart';
import 'package:piv_app/features/admin/presentation/pages/agent_discount_config_page.dart';
import 'package:piv_app/features/admin/presentation/pages/agent_special_price_page.dart';
import 'package:piv_app/features/admin/presentation/pages/agent_product_visibility_page.dart';
import 'package:piv_app/features/sales_commitment/presentation/pages/propose_commitment_form_page.dart';
import 'package:piv_app/features/sales_commitment/presentation/bloc/admin/sales_commitment_admin_cubit.dart';
import 'package:piv_app/core/di/injection_container.dart';

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
    bool? selectedAllowVoucherStacking = user.allowVoucherStacking;
    bool? selectedAgentsAllowVoucherStacking = user.agentsAllowVoucherStacking;

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
                    if (selectedRole == 'sales_rep') ...[
                      const SizedBox(height: 16),
                      const Text('Đại lý của NVKD được phép cộng dồn Voucher?', style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<bool?>(
                        value: selectedAgentsAllowVoucherStacking,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Mặc định (Theo toàn cục)')),
                          DropdownMenuItem(value: true, child: Text('Có')),
                          DropdownMenuItem(value: false, child: Text('Không')),
                        ],
                        onChanged: (value) {
                          setState(() => selectedAgentsAllowVoucherStacking = value);
                        },
                      ),
                    ],
                    if (selectedRole == 'agent_1' || selectedRole == 'agent_2') ...[
                      const SizedBox(height: 16),
                      const Text('Đại lý này được phép cộng dồn Voucher?', style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<bool?>(
                        value: selectedAllowVoucherStacking,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Mặc định (Theo NVKD hoặc Toàn cục)')),
                          DropdownMenuItem(value: true, child: Text('Có')),
                          DropdownMenuItem(value: false, child: Text('Không')),
                        ],
                        onChanged: (value) {
                          setState(() => selectedAllowVoucherStacking = value);
                        },
                      ),
                    ],
                    // Chỉ hiển thị nút cấu hình nếu là đại lý
                    if (selectedRole == 'agent_1' || selectedRole == 'agent_2') ...[
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
                          icon: const Icon(Icons.handshake_outlined),
                          label: const Text('Đề xuất Cam kết Doanh số'),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            Navigator.of(parentContext).push(ProposeCommitmentFormPage.route(
                              sl<SalesCommitmentAdminCubit>(), 
                              user
                            ));
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_month),
                          label: const Text('Cấu hình Hạn Thanh Toán'),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _showDueDaysConfigDialog(parentContext, user);
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.local_offer),
                          label: const Text('Cấu hình Khuyến mãi (Chiết khấu & Voucher)'),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _showPromotionConfigDialog(parentContext, user);
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
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.visibility_off_outlined),
                          label: const Text('Quản lý Hiển thị Sản phẩm'),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            Navigator.of(parentContext).push(MaterialPageRoute(
                              builder: (_) => AgentProductVisibilityPage(agent: user),
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
                    if (selectedAllowVoucherStacking != user.allowVoucherStacking ||
                        selectedAgentsAllowVoucherStacking != user.agentsAllowVoucherStacking) {
                      cubit.updateUserStackingConfig(
                        userId: user.id,
                        allowVoucherStacking: selectedAllowVoucherStacking,
                        agentsAllowVoucherStacking: selectedAgentsAllowVoucherStacking,
                      );
                    }
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

  void _showDueDaysConfigDialog(BuildContext parentContext, UserModel user) {
    final cubit = parentContext.read<AdminUsersCubit>();
    
    // Determine which config to edit based on role
    final bool isSalesRep = user.role == 'sales_rep';
    final currentConfig = isSalesRep ? user.agentsCustomDueDays : user.customDueDays;
    
    final foliarCtrl = TextEditingController(text: currentConfig?['foliar']?.toString() ?? '');
    final rootCtrl = TextEditingController(text: currentConfig?['root']?.toString() ?? '');
    final mixedCtrl = TextEditingController(text: currentConfig?['mixed']?.toString() ?? '');

    showDialog(
      context: parentContext,
      builder: (context) {
        return AlertDialog(
          title: Text(isSalesRep ? 'Hạn thanh toán cho các Đại lý của NVKD' : 'Hạn thanh toán riêng cho Đại lý'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Để trống nếu muốn sử dụng cấu hình mặc định.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: foliarCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Phân bón lá (ngày)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rootCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Phân bón gốc (ngày)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mixedCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Đơn hỗn hợp (ngày)', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Map<String, dynamic>? newConfig;
                if (foliarCtrl.text.isNotEmpty || rootCtrl.text.isNotEmpty || mixedCtrl.text.isNotEmpty) {
                  newConfig = {};
                  if (foliarCtrl.text.isNotEmpty) newConfig['foliar'] = int.tryParse(foliarCtrl.text);
                  if (rootCtrl.text.isNotEmpty) newConfig['root'] = int.tryParse(rootCtrl.text);
                  if (mixedCtrl.text.isNotEmpty) newConfig['mixed'] = int.tryParse(mixedCtrl.text);
                }
                
                cubit.updateUserDueDaysConfig(
                  userId: user.id,
                  customDueDays: isSalesRep ? user.customDueDays : newConfig,
                  agentsCustomDueDays: isSalesRep ? newConfig : user.agentsCustomDueDays,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _showPromotionConfigDialog(BuildContext parentContext, UserModel user) {
    final cubit = parentContext.read<AdminUsersCubit>();
    final bool isSalesRep = user.role == 'sales_rep';
    final currentConfig = isSalesRep ? user.agentsCustomPromotionConfig : user.customPromotionConfig;
    
    // We keep state using StatefulBuilder
    showDialog(
      context: parentContext,
      builder: (context) {
        bool? allowDiscount = currentConfig?['allowDiscount'];
        bool? allowVoucher = currentConfig?['allowVoucher'];
        bool? allowPromotionDuringCommitment = currentConfig?['allowPromotionDuringCommitment'];
        
        return StatefulBuilder(
          builder: (context, setStateBuilder) {
            return AlertDialog(
              title: Text(isSalesRep ? 'Quyền lợi KM cho nhóm ĐL của NVKD' : 'Quyền lợi KM riêng cho Đại lý'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Nếu chọn "Mặc định", hệ thống sẽ sử dụng cấu hình chung của công ty.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<bool?>(
                    value: allowDiscount,
                    decoration: const InputDecoration(labelText: 'Nhận Chiết Khấu'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Mặc định')),
                      DropdownMenuItem(value: true, child: Text('Cho phép')),
                      DropdownMenuItem(value: false, child: Text('Không cho phép')),
                    ],
                    onChanged: (val) => setStateBuilder(() => allowDiscount = val),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<bool?>(
                    value: allowVoucher,
                    decoration: const InputDecoration(labelText: 'Dùng Voucher'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Mặc định')),
                      DropdownMenuItem(value: true, child: Text('Cho phép')),
                      DropdownMenuItem(value: false, child: Text('Không cho phép')),
                    ],
                    onChanged: (val) => setStateBuilder(() => allowVoucher = val),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<bool?>(
                    value: allowPromotionDuringCommitment,
                    decoration: const InputDecoration(labelText: 'Dùng KM khi đang có Cam kết'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Mặc định')),
                      DropdownMenuItem(value: true, child: Text('Cho phép')),
                      DropdownMenuItem(value: false, child: Text('Không cho phép')),
                    ],
                    onChanged: (val) => setStateBuilder(() => allowPromotionDuringCommitment = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Map<String, dynamic>? newConfig;
                    if (allowDiscount != null || allowVoucher != null || allowPromotionDuringCommitment != null) {
                      newConfig = {};
                      if (allowDiscount != null) newConfig['allowDiscount'] = allowDiscount;
                      if (allowVoucher != null) newConfig['allowVoucher'] = allowVoucher;
                      if (allowPromotionDuringCommitment != null) newConfig['allowPromotionDuringCommitment'] = allowPromotionDuringCommitment;
                    }
                    
                    cubit.updateUserPromotionConfig(
                      userId: user.id,
                      customPromotionConfig: isSalesRep ? user.customPromotionConfig : newConfig,
                      agentsCustomPromotionConfig: isSalesRep ? newConfig : user.agentsCustomPromotionConfig,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}