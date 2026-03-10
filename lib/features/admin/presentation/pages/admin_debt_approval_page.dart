import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/admin/data/models/debt_update_request_model.dart';
import 'package:piv_app/features/admin/presentation/bloc/debt_approval_cubit.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';

class AdminDebtApprovalPage extends StatelessWidget {
  const AdminDebtApprovalPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (context) => sl<DebtApprovalCubit>()..watchPendingRequests(),
        child: const AdminDebtApprovalPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final adminId = (context.read<AuthBloc>().state as AuthAuthenticated).user.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyệt yêu cầu công nợ'),
      ),
      body: BlocConsumer<DebtApprovalCubit, DebtApprovalState>(
        listener: (context, state) {
          if (state.status == DebtApprovalStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state.status == DebtApprovalStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.pendingRequests.isEmpty) {
            return const Center(child: Text('Không có yêu cầu nào đang chờ duyệt.'));
          }

          return ListView.builder(
            itemCount: state.pendingRequests.length,
            itemBuilder: (context, index) {
              final request = state.pendingRequests[index];
              final diff = request.newDebtAmount - request.oldDebtAmount;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            request.userName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            dateFormat.format(request.createdAt),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildInfoRow('Người yêu cầu:', request.requestedByName),
                      const SizedBox(height: 4),
                      _buildInfoRow('Công nợ cũ:', currencyFormat.format(request.oldDebtAmount)),
                      _buildInfoRow(
                        'Công nợ mới:', 
                        currencyFormat.format(request.newDebtAmount),
                        valueColor: Colors.blue.shade700,
                        isBold: true,
                      ),
                      _buildInfoRow(
                        'Chênh lệch:', 
                        '${diff > 0 ? "+" : ""}${currencyFormat.format(diff)}',
                        valueColor: diff > 0 ? Colors.red : Colors.green.shade700,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => _showRejectDialog(context, request, adminId),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Từ chối'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => _showApproveConfirm(context, request, adminId),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            child: const Text('Duyệt'),
                          ),
                        ],
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

  Widget _buildInfoRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  void _showApproveConfirm(BuildContext context, DebtUpdateRequestModel request, String adminId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận duyệt'),
        content: Text('Bạn có chắc chắn muốn duyệt yêu cầu thay đổi công nợ cho ${request.userName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              context.read<DebtApprovalCubit>().approveRequest(request.id, adminId);
              Navigator.pop(dialogContext);
            },
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, DebtUpdateRequestModel request, String adminId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Từ chối yêu cầu'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Lý do từ chối'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              context.read<DebtApprovalCubit>().rejectRequest(request.id, adminId, reasonController.text);
              Navigator.pop(dialogContext);
            },
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }
}
