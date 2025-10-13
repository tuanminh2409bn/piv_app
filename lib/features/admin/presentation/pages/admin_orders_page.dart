// lib/features/admin/presentation/pages/admin_orders_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_orders_cubit.dart';
import 'package:piv_app/features/orders/presentation/pages/order_detail_page.dart';

enum OrderFilter { verifying_payment, pending_approval, processing, completed, rejected, all }

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AdminOrdersCubit>()..fetchAllOrders(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý Đơn hàng'),
        ),
        body: const _AdminOrdersView(),
      ),
    );
  }
}

class _AdminOrdersView extends StatefulWidget {
  const _AdminOrdersView();

  @override
  State<_AdminOrdersView> createState() => _AdminOrdersViewState();
}

class _AdminOrdersViewState extends State<_AdminOrdersView> {
  OrderFilter _selectedFilter = OrderFilter.verifying_payment;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        context.read<AdminOrdersCubit>().searchOrders(_searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminOrdersCubit, AdminOrdersState>(
      listener: (context, state) {
        if (state.status == AdminOrdersStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red));
        }
      },
      builder: (context, state) {
        final List<OrderModel> displayedOrders;
        switch (_selectedFilter) {
          case OrderFilter.verifying_payment:
            displayedOrders = state.visibleOrders.where((o) => o.paymentStatus == 'verifying').toList();
            break;
          case OrderFilter.pending_approval:
            displayedOrders = state.visibleOrders.where((o) => o.status == 'pending_approval').toList();
            break;
          case OrderFilter.processing:
          // SỬA ĐỔI: Thêm 'shipped' vào tab "Cần xử lý"
            displayedOrders = state.visibleOrders.where((o) => ['pending', 'processing', 'shipped'].contains(o.status)).toList();
            break;
          case OrderFilter.completed:
          // SỬA ĐỔI: Chỉ giữ lại 'completed' cho tab "Hoàn thành"
            displayedOrders = state.visibleOrders.where((o) => o.status == 'completed').toList();
            break;
          case OrderFilter.rejected:
            displayedOrders = state.visibleOrders.where((o) => ['rejected', 'cancelled'].contains(o.status)).toList();
            break;
          case OrderFilter.all:
            displayedOrders = state.visibleOrders;
            break;
        }

        // --- THÊM BIẾN ĐẾM MỚI ---
        final verifyingPaymentCount = state.visibleOrders.where((o) => o.paymentStatus == 'verifying').length;
        final pendingApprovalCount = state.visibleOrders.where((o) => o.status == 'pending_approval').length;
        // SỬA ĐỔI: Cập nhật biến đếm cho đúng với logic mới
        final processingCount = state.visibleOrders.where((o) => ['pending', 'processing', 'shipped'].contains(o.status)).length;
        final completedCount = state.visibleOrders.where((o) => o.status == 'completed').length;
        final rejectedCount = state.visibleOrders.where((o) => ['rejected', 'cancelled'].contains(o.status)).length;


        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<OrderFilter>(
                  segments: <ButtonSegment<OrderFilter>>[
                    ButtonSegment(value: OrderFilter.verifying_payment, label: Text('Chờ xác nhận TT ($verifyingPaymentCount)'), icon: const Icon(Icons.credit_score_outlined)),
                    ButtonSegment(value: OrderFilter.pending_approval, label: Text('Chờ duyệt ($pendingApprovalCount)'), icon: const Icon(Icons.hourglass_top_outlined)),
                    ButtonSegment(value: OrderFilter.processing, label: Text('Cần xử lý ($processingCount)'), icon: const Icon(Icons.pending_actions_outlined)),
                    ButtonSegment(value: OrderFilter.completed, label: Text('Hoàn thành ($completedCount)'), icon: const Icon(Icons.check_circle_outline)),
                    ButtonSegment(value: OrderFilter.rejected, label: Text('Từ chối/Hủy ($rejectedCount)'), icon: const Icon(Icons.cancel_outlined)),
                    ButtonSegment(value: OrderFilter.all, label: Text('Tất cả (${state.visibleOrders.length})'), icon: const Icon(Icons.inventory_2_outlined)),
                  ],
                  selected: {_selectedFilter},
                  onSelectionChanged: (Set<OrderFilter> newSelection) {
                    setState(() => _selectedFilter = newSelection.first);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm theo mã ĐH, tên hoặc SĐT khách...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _searchController.clear(),
                  )
                      : null,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: state.status == AdminOrdersStatus.loading && displayedOrders.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : displayedOrders.isEmpty
                  ? Center(child: Text('Không có đơn hàng nào phù hợp.'))
                  : RefreshIndicator(
                onRefresh: () => context.read<AdminOrdersCubit>().fetchAllOrders(),
                child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
                    itemCount: displayedOrders.length,
                    itemBuilder: (context, index) {
                      final order = displayedOrders[index];
                      return _buildOrderCard(context, order);
                    }),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final statusInfo = _getStatusInfo(order.status, context);
    const List<String> statusOptions = ['pending_approval', 'pending', 'processing', 'shipped', 'completed', 'cancelled', 'rejected'];
    final usersMap = context.watch<AdminOrdersCubit>().state.usersMap;
    final customerName = usersMap[order.userId]?.displayName ?? order.shippingAddress.recipientName;

    final bool canConfirmPayment = (order.paymentStatus == 'verifying');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (order.id != null) {
            Navigator.of(context).push(OrderDetailPage.route(order.id!));
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Mã đơn: #${order.id?.substring(0, 8).toUpperCase() ?? 'N/A'}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: statusInfo.$1.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(statusInfo.$2, style: TextStyle(color: statusInfo.$1, fontWeight: FontWeight.bold, fontSize: 12)),
                  )
                ],
              ),
              if(order.createdAt != null)
                Text(
                    'Ngày đặt: ${dateFormat.format(order.createdAt!.toDate())}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)
                ),
              _buildPlacedByInfo(context, order, usersMap),
              const Divider(height: 24),
              _buildInfoRow('Khách hàng:', customerName, isBold: true),
              _buildInfoRow('Số điện thoại:', order.shippingAddress.phoneNumber),
              _buildInfoRow('Thanh toán:', _getPaymentStatusText(order.paymentStatus), valueColor: _getPaymentStatusColor(order.paymentStatus)),
              const SizedBox(height: 12),
              _buildInfoRow('Tổng tiền:', currencyFormatter.format(order.finalTotal), isBold: true, valueColor: Theme.of(context).colorScheme.primary),

              if (canConfirmPayment) ...[
                const Divider(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Xác nhận đã thanh toán'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _showPaymentConfirmationDialog(context, orderId: order.id!);
                    },
                  ),
                ),
              ],

              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cập nhật trạng thái:', style: TextStyle(fontWeight: FontWeight.w500)),
                  DropdownButton<String>(
                    value: order.status,
                    icon: const Icon(Icons.arrow_drop_down),
                    underline: Container(height: 2, color: statusInfo.$1),
                    onChanged: (String? newStatus) {
                      if (newStatus != null && newStatus != order.status) {
                         if (newStatus == 'shipped') {
                          _showShippingDatePicker(context, orderId: order.id!);
                      } else {
                         _showStatusChangeConfirmationDialog(
                         context,
                         orderId: order.id!,
                         newStatus: newStatus,
                         newStatusText: _getStatusInfo(newStatus, context).$2,
                         );
                         }
                      }
                    },
                    items: statusOptions.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                          value: value,
                          child: Text(_getStatusInfo(value, context).$2, style: TextStyle(color: _getStatusInfo(value, context).$1, fontWeight: FontWeight.bold))
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShippingDatePicker(BuildContext context, {required String orderId}) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)), // Cho phép chọn ngày hôm qua
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('vi', 'VN'),
      helpText: 'CHỌN NGÀY GIAO DỰ KIẾN',
    );

    if (pickedDate != null && context.mounted) {
      // --- BẮT ĐẦU SỬA LỖI ---
      // Chuẩn hóa ngày về UTC để tránh lỗi múi giờ.
      // Thao tác này tạo một đối tượng DateTime mới với cùng ngày/tháng/năm nhưng múi giờ là UTC.
      final utcDate = DateTime.utc(pickedDate.year, pickedDate.month, pickedDate.day);
      context.read<AdminOrdersCubit>().updateOrderStatusToShipped(orderId, utcDate);
      // --- KẾT THÚC SỬA LỖI ---
    }
  }

  (Color, String) _getStatusInfo(String status, BuildContext context) {
    switch (status) {
      case 'pending_approval': return (Colors.blue.shade700, 'Chờ duyệt');
      case 'pending': return (Colors.orange.shade700, 'Chờ xử lý');
      case 'processing': return (Colors.cyan.shade700, 'Đang xử lý');
      case 'shipped': return (Colors.teal.shade700, 'Đang giao');
      case 'completed': return (Theme.of(context).colorScheme.primary, 'Hoàn thành');
      case 'cancelled': return (Colors.grey.shade700, 'Đã hủy');
      case 'rejected': return (Colors.red.shade700, 'Bị từ chối');
      default: return (Colors.grey.shade700, 'Không xác định');
    }
  }

  String _getPaymentStatusText(String status) {
    switch(status) {
      case 'unpaid': return 'Chưa thanh toán';
      case 'verifying': return 'Chờ xác nhận TT';
      case 'paid': return 'Đã thanh toán';
      default: return status;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch(status) {
      case 'unpaid': return Colors.orange.shade700;
      case 'verifying': return Colors.blue.shade700;
      case 'paid': return Colors.green.shade700;
      default: return Colors.grey;
    }
  }

  void _showPaymentConfirmationDialog(BuildContext context, { required String orderId}) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận thanh toán'),
          content: const Text('Bạn có chắc chắn muốn xác nhận đơn hàng này đã được thanh toán thành công?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('HỦY'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<AdminOrdersCubit>().confirmOrderPayment(orderId);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('XÁC NHẬN'),
            )
          ],
        );
      },
    );
  }

  void _showStatusChangeConfirmationDialog(BuildContext context, {
    required String orderId,
    required String newStatus,
    required String newStatusText,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận thay đổi'),
          content: Text('Bạn có chắc chắn muốn đổi trạng thái đơn hàng thành "$newStatusText"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('HỦY'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<AdminOrdersCubit>().updateOrderStatus(orderId, newStatus);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('XÁC NHẬN'),
            )
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ', style: TextStyle(color: Colors.grey.shade700)),
          Expanded(child: Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: valueColor))),
        ],
      ),
    );
  }

  Widget _buildPlacedByInfo(BuildContext context, OrderModel order, Map<String, UserModel> usersMap) {
    if (order.placedBy == null) {
      return const SizedBox.shrink();
    }
    final placerId = order.placedBy!.userId;
    final placerName = usersMap[placerId]?.displayName ?? 'ID: ${placerId.substring(0,8)}';
    final placerRole = _translateRole(order.placedBy!.role);

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(color: Colors.blueGrey.shade700, fontSize: 13),
          children: [
            const TextSpan(text: 'Đặt bởi: '),
            TextSpan(
              text: placerName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: ' ($placerRole)'),
          ],
        ),
      ),
    );
  }

  String _translateRole(String role) {
    switch (role) {
      case 'sales_rep': return 'NVKD';
      case 'accountant': return 'Kế toán';
      case 'admin': return 'Admin';
      default: return role;
    }
  }
}