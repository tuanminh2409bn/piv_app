import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/data/models/discount_policy_model.dart';
import 'package:piv_app/features/admin/presentation/bloc/agent_discount_cubit.dart';
import 'package:piv_app/features/admin/presentation/widgets/tier_table_editor.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';

class AgentDiscountConfigPage extends StatelessWidget {
  final UserModel user;

  const AgentDiscountConfigPage({super.key, required this.user});

  static Route route({required UserModel user}) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (context) => AgentDiscountCubit(
          repository: sl(),
          authBloc: context.read<AuthBloc>(),
          agentId: user.id,
        )..init(),
        child: AgentDiscountConfigPage(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const AgentDiscountConfigView();
  }
}

class AgentDiscountConfigView extends StatefulWidget {
  const AgentDiscountConfigView({super.key});

  @override
  State<AgentDiscountConfigView> createState() => _AgentDiscountConfigViewState();
}

class _AgentDiscountConfigViewState extends State<AgentDiscountConfigView> {
  late bool _enabled;
  late AgentPolicy _currentPolicy;
  late UserModel _user;

  @override
  void initState() {
    super.initState();
    // Lấy user từ widget cha (thông qua context hoặc constructor, ở đây dùng tạm trick lấy từ parent widget cũ, nhưng do tôi refactor sang StatelessWidget + View nên cần lấy lại)
    // Cách tốt nhất là truyền user vào View. Nhưng để đơn giản tôi sẽ giả định widget cha truyền đúng.
    // Sửa lại: Truyền user từ Page xuống View
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final page = context.findAncestorWidgetOfExactType<AgentDiscountConfigPage>();
    if (page != null) {
      _user = page.user;
      _enabled = _user.customDiscountEnabled;
      if (_user.customDiscount != null && _user.customDiscount!['policy'] != null) {
        _currentPolicy = AgentPolicy.fromJson(_user.customDiscount!['policy']);
      } else {
        _currentPolicy = AgentPolicy(
          foliar: ProductTypePolicy(tiers: []),
          root: ProductTypePolicy(tiers: []),
        );
      }
    }
  }

  void _saveConfig() {
    context.read<AgentDiscountCubit>().saveConfig(
      agent: _user,
      enabled: _enabled,
      policy: _currentPolicy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUserRole = (authState is AuthAuthenticated) ? authState.user.role : 'sales_rep';
    final isAdmin = currentUserRole == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cấu hình Chiết khấu Riêng'),
      ),
      body: BlocConsumer<AgentDiscountCubit, AgentDiscountState>(
        listener: (context, state) {
          if (state.status == AgentDiscountStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage ?? 'Thành công!'),
                backgroundColor: Colors.green,
              ),
            );
            if (!isAdmin) {
              Navigator.pop(context); // NVKD gửi xong thì thoát ra
            }
          }
          if (state.status == AgentDiscountStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Đã có lỗi xảy ra'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == AgentDiscountStatus.loading && state.pendingRequest == null) {
             // Chỉ hiện loading khi save, còn init load pending request thì ko cần chặn màn hình
             return const Center(child: CircularProgressIndicator());
          }

          final hasPending = state.pendingRequest != null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserInfoCard(_user),
                
                if (hasPending)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Đang có yêu cầu chờ duyệt', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                              const SizedBox(height: 4),
                              Text('Yêu cầu gửi ngày: ${state.pendingRequest!.createdAt.toDate().toString().split('.')[0]}', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),
                SwitchListTile(
                  title: const Text('Kích hoạt cấu hình riêng', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Khi bật, đại lý sẽ dùng bảng chiết khấu này thay vì của hệ thống.'),
                  value: _enabled,
                  onChanged: (val) => setState(() => _enabled = val),
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(height: 32),
                
                if (_enabled) ...[
                  TierTableEditor(
                    title: 'Phân Bón Lá',
                    color: Colors.green.shade100,
                    tiers: _currentPolicy.foliar.tiers,
                    onChanged: (newTiers) {
                      setState(() {
                        _currentPolicy = AgentPolicy(
                          foliar: ProductTypePolicy(tiers: newTiers),
                          root: _currentPolicy.root,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  TierTableEditor(
                    title: 'Phân Bón Gốc',
                    color: Colors.brown.shade100,
                    tiers: _currentPolicy.root.tiers,
                    onChanged: (newTiers) {
                      setState(() {
                        _currentPolicy = AgentPolicy(
                          foliar: _currentPolicy.foliar,
                          root: ProductTypePolicy(tiers: newTiers),
                        );
                      });
                    },
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Đại lý sẽ sử dụng mức chiết khấu chung của hệ thống (dựa trên doanh số tích lũy).',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.status == AgentDiscountStatus.loading ? null : () {
                       // --- VALIDATION: Chỉ kiểm tra nếu đang BẬT ---
                       if (_enabled) {
                         final bool hasFoliar = _currentPolicy.foliar.tiers.isNotEmpty;
                         final bool hasRoot = _currentPolicy.root.tiers.isNotEmpty;

                         if (!hasFoliar && !hasRoot) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(
                               content: Text('Vui lòng cấu hình ít nhất 1 nấc chiết khấu (Lá hoặc Gốc) khi bật cấu hình riêng.'),
                               backgroundColor: Colors.red,
                               behavior: SnackBarBehavior.floating,
                             ),
                           );
                           return;
                         }
                       }
                       
                       _saveConfig();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: state.status == AgentDiscountStatus.loading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(isAdmin ? 'LƯU & ÁP DỤNG NGAY' : (hasPending ? 'CẬP NHẬT YÊU CẦU' : 'GỬI YÊU CẦU DUYỆT')),
                  ),
                ),
                if (!isAdmin && hasPending)
                   Padding(
                     padding: const EdgeInsets.only(top: 8.0),
                     child: const Center(child: Text('Bạn đã gửi một yêu cầu, gửi lại sẽ cập nhật yêu cầu cũ.', style: TextStyle(color: Colors.grey, fontSize: 12))),
                   ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserInfoCard(UserModel user) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(user.displayName?[0].toUpperCase() ?? 'A')),
        title: Text(user.displayName ?? 'Chưa có tên', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(user.email ?? 'Chưa có email'),
        trailing: Chip(
          label: Text(user.status == 'active' ? 'Đã duyệt' : 'Chưa duyệt'),
          backgroundColor: user.status == 'active' ? Colors.green.shade100 : Colors.orange.shade100,
          labelStyle: TextStyle(color: user.status == 'active' ? Colors.green.shade800 : Colors.orange.shade800),
        ),
      ),
    );
  }
}