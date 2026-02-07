import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/admin/data/models/discount_request_model.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_discount_requests_cubit.dart';

class AdminDiscountRequestsPage extends StatelessWidget {
  const AdminDiscountRequestsPage({super.key});

  static Route route() {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (context) => sl<AdminDiscountRequestsCubit>(),
        child: const AdminDiscountRequestsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Duyệt Yêu Cầu Chiết Khấu')),
      body: BlocBuilder<AdminDiscountRequestsCubit, AdminDiscountRequestsState>(
        builder: (context, state) {
          if (state.requests.isEmpty) {
            return const Center(child: Text('Không có yêu cầu nào đang chờ duyệt.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = state.requests[index];
              return _RequestCard(request: request);
            },
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  final DiscountRequestModel request;

  const _RequestCard({required this.request});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  // Lưu trạng thái checked của các nấc. Key dạng 'foliar_0', 'root_1'
  final Map<String, bool> _checkedTiers = {};
  late Map<String, dynamic> _policyData;

  @override
  void initState() {
    super.initState();
    _initPolicyData();
  }

  void _initPolicyData() {
    _policyData = Map<String, dynamic>.from(widget.request.customDiscount['policy'] ?? {});
    
    // Mặc định check tất cả
    final foliarTiers = _getTiersList('foliar');
    for (int i = 0; i < foliarTiers.length; i++) {
      _checkedTiers['foliar_$i'] = true;
    }
    
    final rootTiers = _getTiersList('root');
    for (int i = 0; i < rootTiers.length; i++) {
      _checkedTiers['root_$i'] = true;
    }
  }

  List _getTiersList(String type) {
    if (_policyData[type] != null && _policyData[type]['tiers'] != null) {
      return _policyData[type]['tiers'] as List;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.request.agentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
                  child: const Text('Chờ duyệt', style: TextStyle(fontSize: 12, color: Colors.orange)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Yêu cầu bởi: ${widget.request.requesterName} (${widget.request.requesterRole == 'sales_rep' ? 'NVKD' : 'Kế toán'})'),
            Text('Thời gian: ${dateFormat.format(widget.request.createdAt.toDate())}'),
            const SizedBox(height: 12),
            _buildProposedPolicy(),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _showRejectDialog(context),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('TỪ CHỐI'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _confirmApprove(context),
                  child: const Text('DUYỆT'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProposedPolicy() {
    final bool isEnabled = widget.request.customDiscount['enabled'] ?? true;

    if (!isEnabled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Yêu cầu QUAY VỀ mức chiết khấu hệ thống (Xóa cấu hình riêng).',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Trạng thái kích hoạt: ', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(isEnabled ? 'BẬT' : 'TẮT', style: TextStyle(color: isEnabled ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          _buildTypeSection('Phân Bón Lá', 'foliar'),
          const SizedBox(height: 8),
          _buildTypeSection('Phân Bón Gốc', 'root'),
        ],
      ),
    );
  }

  Widget _buildTypeSection(String title, String typeKey) {
    final tiers = _getTiersList(typeKey);
    if (tiers.isEmpty) return Text('$title: Không có chiết khấu');

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
        ...tiers.asMap().entries.map((entry) {
          final index = entry.key;
          final t = entry.value;
          final min = (t['minAmount'] as num).toDouble();
          final rate = (t['rate'] as num).toDouble() * 100;
          final key = '${typeKey}_$index';

          return CheckboxListTile(
            title: Text('Từ ${currencyFormat.format(min)}: Giảm $rate%'),
            value: _checkedTiers[key] ?? false,
            onChanged: (val) {
              setState(() {
                _checkedTiers[key] = val ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          );
        }),
      ],
    );
  }

  void _confirmApprove(BuildContext context) {
    // Xây dựng cấu hình mới dựa trên checkbox
    final newFoliarTiers = _getSelectedTiers('foliar');
    final newRootTiers = _getSelectedTiers('root');

    final Map<String, dynamic> modifiedConfig = {
      'enabled': widget.request.customDiscount['enabled'], // Giữ nguyên trạng thái bật tắt
      'policy': {
        'foliar': {'tiers': newFoliarTiers},
        'root': {'tiers': newRootTiers},
      }
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận duyệt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn sẽ duyệt chiết khấu cho đại lý này với các mục đã chọn.'),
            const SizedBox(height: 8),
            Text('- Phân bón lá: ${newFoliarTiers.length} nấc'),
            Text('- Phân bón gốc: ${newRootTiers.length} nấc'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('HỦY')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminDiscountRequestsCubit>().approveRequest(
                widget.request,
                modifiedConfig: modifiedConfig,
              );
            },
            child: const Text('ĐỒNG Ý'),
          ),
        ],
      ),
    );
  }

  List<dynamic> _getSelectedTiers(String typeKey) {
    final allTiers = _getTiersList(typeKey);
    final selectedTiers = <dynamic>[];
    for (int i = 0; i < allTiers.length; i++) {
      if (_checkedTiers['${typeKey}_$i'] == true) {
        selectedTiers.add(allTiers[i]);
      }
    }
    return selectedTiers;
  }

  void _showRejectDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối yêu cầu'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Lý do từ chối', border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('HỦY')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminDiscountRequestsCubit>().rejectRequest(widget.request.id, controller.text);
            },
            child: const Text('TỪ CHỐI', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}