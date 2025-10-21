//lib/features/vouchers/presentation/pages/voucher_management_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';
import 'package:piv_app/features/vouchers/presentation/bloc/voucher_management_cubit.dart';
import 'package:piv_app/features/vouchers/presentation/pages/voucher_form_page.dart';

class VoucherManagementPage extends StatelessWidget {
  const VoucherManagementPage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (context) => sl<VoucherManagementCubit>()..getVouchers(),
        child: const VoucherManagementPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const VoucherManagementView();
  }
}

class VoucherManagementView extends StatelessWidget {
  const VoucherManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Voucher')),
      body: BlocBuilder<VoucherManagementCubit, VoucherManagementState>(
        builder: (context, state) {
          if (state.status == VoucherManagementStatus.loading && state.vouchers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == VoucherManagementStatus.error) {
            return Center(child: Text(state.errorMessage ?? 'Lỗi tải dữ liệu'));
          }
          if (state.vouchers.isEmpty) {
            return const Center(child: Text('Bạn chưa tạo voucher nào.'));
          }

          return ListView.builder(
            itemCount: state.vouchers.length,
            itemBuilder: (context, index) {
              final voucher = state.vouchers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(voucher.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(voucher.description), // Giữ lại mô tả
                      // Thêm phần hiển thị lý do nếu có
                      Builder( // Dùng Builder để gọi hàm helper dễ dàng
                        builder: (context) {
                          // Luôn gọi _getRejectionReason để kiểm tra
                          final reason = _getRejectionReason(voucher);
                          // Chỉ hiển thị nếu tìm thấy lý do (cho cả reject tạo/sửa VÀ reject xóa)
                          if (reason != null) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Lý do từ chối: $reason',
                                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                                maxLines: 2, // Giới hạn 2 dòng nếu lý do quá dài
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }
                          return const SizedBox.shrink(); // Không hiển thị gì nếu không có lý do
                        },
                      ),
                    ],
                  ),
                  isThreeLine: _getRejectionReason(voucher) != null, // Cho phép ListTile hiển thị 3 dòng nếu có lý do
                  trailing: _buildTrailingActions(context, voucher),
                  onTap: () {
                    // Bọc VoucherFormPage trong BlocProvider.value để nó có thể truy cập cubit
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: BlocProvider.of<VoucherManagementCubit>(context),
                          child: VoucherFormPage(voucher: voucher),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: BlocProvider.of<VoucherManagementCubit>(context),
                child: const VoucherFormPage(),
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    switch (status) {
      case VoucherStatus.active:
        color = Colors.green;
        text = 'Hoạt động';
        break;
      case VoucherStatus.pendingApproval:
        color = Colors.orange;
        text = 'Chờ duyệt';
        break;
      case VoucherStatus.pendingDeletion:
        color = Colors.red;
        text = 'Chờ xóa';
        break;
      case VoucherStatus.rejected:
        color = Colors.grey;
        text = 'Bị từ chối';
        break;
      default:
        color = Colors.grey.shade400;
        text = 'Không hoạt động';
    }
    return Chip(
      label: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      labelPadding: EdgeInsets.zero,
    );
  }

  Widget _buildTrailingActions(BuildContext context, VoucherModel voucher) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusChip(voucher.status), // Giữ lại chip trạng thái
        const SizedBox(width: 8),
        // Thêm nút Xóa (biểu tượng thùng rác)
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            // Làm mờ nút nếu đang chờ xóa
            color: voucher.status == VoucherStatus.pendingDeletion ? Colors.grey : Colors.red,
          ),
          tooltip: 'Yêu cầu xóa voucher',
          // Vô hiệu hóa nút nếu đang chờ xóa để tránh nhấn nhiều lần
          onPressed: voucher.status == VoucherStatus.pendingDeletion
              ? null // Vô hiệu hóa
              : () => _confirmDelete(context, voucher), // Mở hộp thoại xác nhận
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, VoucherModel voucher) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Yêu cầu Xóa Voucher'),
        content: Text('Bạn có chắc chắn muốn gửi yêu cầu xóa voucher "${voucher.id}"?\n\nAdmin sẽ cần phê duyệt yêu cầu này.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('HỦY'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              // Gọi hàm requestDeleteVoucher từ Cubit
              context.read<VoucherManagementCubit>().requestDeleteVoucher(voucher);
              Navigator.of(dialogContext).pop(); // Đóng hộp thoại
            },
            child: const Text('YÊU CẦU XÓA'),
          ),
        ],
      ),
    );
  }

  String? _getRejectionReason(VoucherModel voucher) {
    if (voucher.status != VoucherStatus.rejected && voucher.status != VoucherStatus.inactive) { // Có thể inactive sau khi bị từ chối xóa
      return null;
    }
    // Tìm mục lịch sử từ chối gần nhất
    final rejectionEntry = voucher.history.lastWhere(
          (entry) => entry.action == 'rejected' || entry.action == 'deletion_rejected',
      orElse: () => VoucherHistoryEntry(action: '', actorId: '', timestamp: null!), // Trả về entry rỗng nếu không tìm thấy
    );
    // Trả về ghi chú, đảm bảo không rỗng
    return rejectionEntry.notes?.isNotEmpty == true ? rejectionEntry.notes : null;
  }
}