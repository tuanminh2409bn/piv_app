// lib/features/returns/presentation/pages/create_return_request_page.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/data/models/order_item_model.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/data/models/return_policy_config_model.dart'; // Added import
import 'package:piv_app/features/returns/presentation/bloc/create_return_request_cubit.dart';

class CreateReturnRequestPage extends StatelessWidget {
  final OrderModel order;
  const CreateReturnRequestPage({super.key, required this.order});

  static PageRoute<void> route(OrderModel order) {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (_) => sl<CreateReturnRequestCubit>()..loadPolicy(),
        child: CreateReturnRequestPage(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CreateReturnRequestView(order: order);
  }
}

class CreateReturnRequestView extends StatefulWidget {
  final OrderModel order;
  const CreateReturnRequestView({super.key, required this.order});

  @override
  State<CreateReturnRequestView> createState() =>
      _CreateReturnRequestViewState();
}

class _CreateReturnRequestViewState extends State<CreateReturnRequestView> {
  final _notesController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedReason = 'Sản phẩm bị hỏng/vỡ';

  final List<String> _reasons = [
    'Sản phẩm bị hỏng/vỡ',
    'Giao sai sản phẩm',
    'Sản phẩm hết hạn sử dụng',
    'Không đúng như mô tả',
    'Lý do khác'
  ];

  double _calculatedPenalty = 0.0;
  double _calculatedRefund = 0.0;
  String _policyMessage = '';

  @override
  void dispose() {
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _calculatePenalty(OrderModel order, CreateReturnRequestState state) {
    double totalRefund = 0;
    state.returnedItems.forEach((productId, returnedQuantity) {
      if (returnedQuantity > 0) {
        final originalItem =
            order.items.firstWhere((item) => item.productId == productId);
        totalRefund += returnedQuantity * originalItem.price;
      }
    });

    if (order.createdAt == null) {
      if (mounted) {
        setState(() {
          _calculatedPenalty = 0.0;
          _calculatedRefund = totalRefund;
          _policyMessage = 'Không thể xác định ngày tạo đơn hàng.';
        });
      }
      return;
    }

    final daysDifference =
        DateTime.now().difference(order.createdAt!.toDate()).inDays;
    final monthsDifference = daysDifference / 30;

    double penaltyPerCrate = 0;
    final policy = state.policy;

    if (policy != null) {
      if (monthsDifference > policy.maxReturnMonths) {
        _policyMessage = 'Đơn hàng quá ${policy.maxReturnMonths} tháng. Có thể bị từ chối.';
        penaltyPerCrate = 0; // Hoặc xử lý khác tùy logic
      } else {
        // Tìm tier phù hợp
        final tier = policy.tiers.firstWhere(
          (t) => monthsDifference > t.minMonths && monthsDifference <= t.maxMonths,
          orElse: () => policy.tiers.isNotEmpty
            ? policy.tiers.last // Fallback an toàn
            : const ReturnPolicyTier(minMonths: 0, maxMonths: 0, penaltyPerCrate: 0),
        );
        
        // Fix trường hợp monthsDifference <= 0 hoặc min tier start 0
        if (monthsDifference <= 0 && policy.tiers.isNotEmpty) {
             penaltyPerCrate = policy.tiers.first.penaltyPerCrate;
             _policyMessage = _getPolicyMessage(policy.tiers.first);
        } else {
             penaltyPerCrate = tier.penaltyPerCrate;
             _policyMessage = _getPolicyMessage(tier);
        }
      }
    } else {
      // Fallback nếu chưa load được policy (giữ logic cũ hoặc hiện loading)
      if (monthsDifference > 24) {
        _policyMessage = 'Đơn hàng quá 24 tháng. Có thể bị từ chối.';
        penaltyPerCrate = 0;
      } else if (monthsDifference > 12) {
        _policyMessage = 'Phí phạt: 300.000 đ/thùng (sau 12 tháng)';
        penaltyPerCrate = 300000;
      } else if (monthsDifference > 3) {
        _policyMessage = 'Phí phạt: 150.000 đ/thùng (sau 3 tháng)';
        penaltyPerCrate = 150000;
      } else {
        _policyMessage = 'Miễn phí đổi trả (trong 3 tháng đầu)';
        penaltyPerCrate = 0;
      }
    }

    double totalCratesToReturn = 0;
    state.returnedItems.forEach((productId, returnedQuantity) {
      if (returnedQuantity > 0) {
        final originalItem =
            order.items.firstWhere((item) => item.productId == productId);
        final crates =
            (returnedQuantity / originalItem.quantityPerPackage).ceil();
        totalCratesToReturn += crates;
      }
    });

    if (mounted) {
      setState(() {
        _calculatedRefund = totalRefund;
        _calculatedPenalty =
            penaltyPerCrate > 0 ? totalCratesToReturn * penaltyPerCrate : 0.0;
      });
    }
  }

  String _getPolicyMessage(ReturnPolicyTier tier) {
     final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
     if (tier.penaltyPerCrate == 0) {
       return 'Miễn phí đổi trả (từ ${tier.minMonths} - ${tier.maxMonths} tháng)';
     }
     return 'Phí phạt: ${formatter.format(tier.penaltyPerCrate)}/thùng (từ ${tier.minMonths} - ${tier.maxMonths} tháng)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Màu nền sáng hiện đại
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Yêu cầu Đổi/Trả',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: const BackButton(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppTheme.primaryGreen),
            onPressed: () {
              _showPolicyDialog(context);
            },
          )
        ],
      ),
      body: BlocConsumer<CreateReturnRequestCubit, CreateReturnRequestState>(
        listenWhen: (prev, curr) =>
            prev.returnedItems != curr.returnedItems ||
            prev.status != curr.status,
        listener: (context, state) {
          _calculatePenalty(widget.order, state);

          if (state.status == CreateReturnRequestStatus.error) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(state.errorMessage ?? 'Có lỗi xảy ra'),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
              ));
          } else if (state.status == CreateReturnRequestStatus.success) {
            _showSuccessDialog(context);
          }
        },
        builder: (context, state) {
          final bool hasItems = state.returnedItems.values.any((q) => q > 0);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderOrderInfo(),
                      const SizedBox(height: 20),
                      _buildSectionHeader('1. Chọn sản phẩm cần đổi/trả'),
                      const SizedBox(height: 12),
                      _buildProductList(context, widget.order, state),
                      const SizedBox(height: 24),
                      _buildSectionHeader('2. Lý do đổi/trả'),
                      const SizedBox(height: 12),
                      _buildReasonSelector(context),
                      const SizedBox(height: 24),
                      _buildSectionHeader('3. Hình ảnh bằng chứng'),
                      const SizedBox(height: 12),
                      _buildImageUpload(context, state),
                      const SizedBox(height: 24),
                      _buildSectionHeader('4. Ghi chú thêm'),
                      const SizedBox(height: 12),
                      _buildNoteInput(),
                      const SizedBox(height: 100), // Space for bottom bar
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.05, end: 0),
                ),
              ),
              _buildBottomSummaryBar(context, state, hasItems),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGETS CON ---

  Widget _buildHeaderOrderInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đơn hàng #${widget.order.id?.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ngày tạo: ${widget.order.createdAt != null ? DateFormat('dd/MM/yyyy').format(widget.order.createdAt!.toDate()) : 'N/A'}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
        color: AppTheme.textGrey,
      ),
    );
  }

  Widget _buildProductList(
      BuildContext context, OrderModel order, CreateReturnRequestState state) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: order.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = order.items[index];
        final returnedQuantity = state.returnedItems[item.productId] ?? 0;
        final maxQuantity = item.quantity * item.quantityPerPackage;
        final isSelected = returnedQuantity > 0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: isSelected,
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.image_not_supported, size: 20),
                  ),
                ),
              ),
              title: Text(
                item.productName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87),
              ),
              subtitle: Text(
                'Đã mua: ${item.packaging.contains('thùng') ? 'thùng' : item.packaging} (Tổng: $maxQuantity ${item.unit})',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              trailing: isSelected
                  ? Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: AppTheme.primaryGreen, shape: BoxShape.circle),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 16),
                    )
                  : const Icon(Icons.circle_outlined, color: Colors.grey),
              onExpansionChanged: (expanded) {
                // Removed auto-select logic to give user full control
              },
              children: [
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                  child: Column(
                    children: [
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('Số lượng trả lại (${item.unit}):',
                                style: const TextStyle(fontWeight: FontWeight.w500)),
                          ),
                          _buildQuantityControl(
                              context, item, returnedQuantity, maxQuantity),
                        ],
                      ),
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Hoàn lại: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(returnedQuantity * item.price)}',
                              style: TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuantityControl(BuildContext context, OrderItemModel item,
      int current, int max) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () => context
                .read<CreateReturnRequestCubit>()
                .updateReturnQuantity(item, current - 1),
          ),
          InkWell(
            onTap: () => _showQuantityDialog(context, item, current, max),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              constraints: const BoxConstraints(minWidth: 40),
              child: Text(
                '$current',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => context
                .read<CreateReturnRequestCubit>()
                .updateReturnQuantity(item, current + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSelector(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: _reasons.map((reason) {
          final isSelected = _selectedReason == reason;
          return Column(
            children: [
              RadioListTile<String>(
                value: reason,
                groupValue: _selectedReason,
                activeColor: AppTheme.primaryGreen,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(
                  reason,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.black87 : Colors.black54,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _selectedReason = val!;
                  });
                },
              ),
              if (reason != _reasons.last)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildImageUpload(
      BuildContext context, CreateReturnRequestState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.images.isNotEmpty)
            Container(
              height: 100,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(state.images[index],
                            width: 100, height: 100, fit: BoxFit.cover),
                      ),
                      GestureDetector(
                        onTap: () => context
                            .read<CreateReturnRequestCubit>()
                            .removeImage(state.images[index]),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              size: 16, color: Colors.red),
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
          InkWell(
            onTap: () => context.read<CreateReturnRequestCubit>().pickImages(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.5),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined,
                      color: AppTheme.primaryGreen.withOpacity(0.8)),
                  const SizedBox(width: 8),
                  Text(
                    'Tải lên hình ảnh',
                    style: TextStyle(
                        color: AppTheme.primaryGreen.withOpacity(0.8),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: 'Nhập chi tiết vấn đề...',
          border: OutlineInputBorder(borderSide: BorderSide.none),
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildBottomSummaryBar(
      BuildContext context, CreateReturnRequestState state, bool hasItems) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final actualRefund =
        (_calculatedRefund - _calculatedPenalty).clamp(0, double.infinity);

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng hoàn lại (dự kiến):',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
              Text(
                formatter.format(actualRefund),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen),
              ),
            ],
          ),
          if (_calculatedPenalty > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '(Đã trừ phí phạt: ${formatter.format(_calculatedPenalty)})',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade400),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: !hasItems ||
                      state.status == CreateReturnRequestStatus.submitting
                  ? null
                  : () {
                      context.read<CreateReturnRequestCubit>().submitRequest(
                            order: widget.order,
                            reason: _selectedReason,
                            userNotes: _notesController.text.trim(),
                            penaltyFee: _calculatedPenalty,
                            refundAmount: _calculatedRefund,
                          );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: state.status == CreateReturnRequestStatus.submitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text(
                      'GỬI YÊU CẦU',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // --- DIALOGS ---

  Future<void> _showQuantityDialog(
      BuildContext context, OrderItemModel item, int current, int max) async {
    final controller = TextEditingController(text: current.toString());
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhập số lượng'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
              suffixText: item.unit, border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text) ?? 0;
              if (val >= 0 && val <= max) {
                context
                    .read<CreateReturnRequestCubit>()
                    .updateReturnQuantity(item, val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _showPolicyDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                const Text('Quy định đổi trả',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildPolicyItem('Miễn phí', 'Đổi trả trong 3 tháng đầu.'),
            _buildPolicyItem('Phí 150.000đ/thùng', 'Từ 3 - 12 tháng.'),
            _buildPolicyItem('Phí 300.000đ/thùng', 'Từ 12 - 24 tháng.'),
            _buildPolicyItem(
                'Từ chối', 'Sau 24 tháng (tùy quyết định công ty).'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đã hiểu'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(
                      text: '$title: ',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.green.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle,
                  color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gửi yêu cầu thành công!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chúng tôi sẽ xem xét và phản hồi sớm nhất.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Back to Order Detail
            },
            child: const Text('VỀ ĐƠN HÀNG'),
          ),
        ],
      ),
    );
  }
}