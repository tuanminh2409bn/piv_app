import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/data/models/price_request_model.dart';
import 'package:piv_app/features/admin/presentation/bloc/price_approval_cubit.dart';

class PriceApprovalPage extends StatelessWidget {
  const PriceApprovalPage({super.key});

  static Route route() {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => PriceApprovalCubit(
          repository: sl(),
          authBloc: sl(),
        ),
        child: const PriceApprovalPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Duyệt thay đổi giá')),
      body: BlocBuilder<PriceApprovalCubit, PriceApprovalState>(
        builder: (context, state) {
          if (state.status == PriceApprovalStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == PriceApprovalStatus.error) {
            return Center(child: Text(state.errorMessage ?? 'Có lỗi xảy ra'));
          }
          if (state.pendingRequests.isEmpty) {
            return const Center(child: Text('Không có yêu cầu nào đang chờ duyệt.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.pendingRequests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = state.pendingRequests[index];
              return _RequestCard(request: request);
            },
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  final PriceRequestModel request;
  const _RequestCard({required this.request});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  // Set lưu ID của các sản phẩm được chọn để duyệt
  late Set<String> _selectedProductIds;

  @override
  void initState() {
    super.initState();
    // Mặc định chọn tất cả
    _selectedProductIds = widget.request.items.map((e) => e.productId).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('HH:mm dd/MM/yyyy');

    IconData icon;
    Color color;
    String title;
    Widget details;

    switch (widget.request.type) {
      case 'update_price_batch': // Sửa đúng type
        icon = Icons.price_change;
        color = Colors.blue;
        title = 'Cập nhật giá (${widget.request.items.length} sản phẩm)';
        details = Column(
          children: widget.request.items.map((item) {
            final isRemoval = item.newPrice <= 0;
            final isSelected = _selectedProductIds.contains(item.productId);
            
            return CheckboxListTile(
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedProductIds.add(item.productId);
                  } else {
                    _selectedProductIds.remove(item.productId);
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              secondary: item.productImageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(item.productImageUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image, size: 40)),
                    )
                  : const Icon(Icons.image, size: 40),
              title: Text(item.productName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giá niêm yết: ${currencyFormat.format(item.generalPrice)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Row(
                    children: [
                      if (item.oldPrice > 0) ...[
                        Text(
                          'Giá riêng cũ: ${currencyFormat.format(item.oldPrice)}', 
                          style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 12)
                        ),
                        const Icon(Icons.arrow_right_alt, size: 16, color: Colors.grey),
                      ],
                      Text(
                        isRemoval ? 'Về giá gốc' : 'Giá đề xuất: ${currencyFormat.format(item.newPrice)}',
                        style: TextStyle(color: isRemoval ? Colors.red : Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
        break;
      case 'toggle_mode':
        icon = Icons.settings_brightness;
        color = Colors.orange;
        title = 'Đổi chế độ giá';
        details = Text(
          'Chuyển sang: ${widget.request.newGeneralPriceState == true ? "Sử dụng Giá chung" : "Sử dụng Giá riêng"}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        );
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
        title = 'Yêu cầu không xác định (${widget.request.type})';
        details = const SizedBox.shrink();
    }

    // Logic nút duyệt
    final isBatchUpdate = widget.request.type == 'update_price_batch';
    final int selectedCount = _selectedProductIds.length;
    final int totalCount = widget.request.items.length;
    String approveButtonText = 'DUYỆT';
    
    if (isBatchUpdate) {
      if (selectedCount == totalCount) {
        approveButtonText = 'DUYỆT TẤT CẢ';
      } else if (selectedCount > 0) {
        approveButtonText = 'DUYỆT (${selectedCount}) MỤC';
      } else {
        approveButtonText = 'TỪ CHỐI TẤT CẢ'; // Không chọn gì thì thành từ chối
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: Icon(icon, color: color),
          title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Đại lý: ${widget.request.agentName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('Yêu cầu bởi: ${widget.request.requesterName} • ${dateFormat.format(widget.request.createdAt.toDate())}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const Divider(),
            details,
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showRejectDialog(context),
                  child: const Text('TỪ CHỐI', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  // Vô hiệu hóa nút duyệt nếu là batch update mà chưa chọn gì (hoặc chuyển thành nút từ chối như logic trên)
                  onPressed: (isBatchUpdate && selectedCount == 0)
                      ? () => _showRejectDialog(context) // Nếu không chọn gì -> Từ chối
                      : () {
                          // Nếu là batch update, tạo bản sao request chỉ chứa items đã chọn
                          if (isBatchUpdate) {
                            // Lọc danh sách items
                            final filteredItems = widget.request.items
                                .where((item) => _selectedProductIds.contains(item.productId))
                                .toList();
                            
                            // Tạo request mới với danh sách đã lọc (dùng copyWith không được vì items là list, phải tạo mới hoặc sửa model để copy list)
                            // Cách đơn giản: Tạo request mới thủ công
                            final partialRequest = PriceRequestModel(
                              id: widget.request.id,
                              agentId: widget.request.agentId,
                              agentName: widget.request.agentName,
                              requesterId: widget.request.requesterId,
                              requesterName: widget.request.requesterName,
                              requesterRole: widget.request.requesterRole,
                              type: widget.request.type,
                              items: filteredItems, // CHỈ GỬI ITEM ĐƯỢC DUYỆT
                              newGeneralPriceState: widget.request.newGeneralPriceState,
                              status: widget.request.status,
                              createdAt: widget.request.createdAt,
                            );
                            
                            context.read<PriceApprovalCubit>().approveRequest(partialRequest);
                          } else {
                            // Các loại request khác duyệt bình thường
                            context.read<PriceApprovalCubit>().approveRequest(widget.request);
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                  child: Text(approveButtonText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Từ chối yêu cầu'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Lý do từ chối (tùy chọn)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              context.read<PriceApprovalCubit>().rejectRequest(widget.request.id, controller.text);
              Navigator.pop(dialogContext);
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}
