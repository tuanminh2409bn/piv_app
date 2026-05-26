// lib/features/admin/presentation/pages/price_adjustment_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/admin/presentation/bloc/price_adjustment_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/price_adjustment_state.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';

class PriceAdjustmentPage extends StatefulWidget {
  const PriceAdjustmentPage({super.key});

  static PageRoute route() {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (context) => sl<PriceAdjustmentCubit>()..loadAgents(),
        child: const PriceAdjustmentPage(),
      ),
    );
  }

  @override
  State<PriceAdjustmentPage> createState() => _PriceAdjustmentPageState();
}

class _PriceAdjustmentPageState extends State<PriceAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _formatter = NumberFormat.decimalPattern('vi_VN');

  // Loại giá: general | special_adjust | special_from_general
  String _priceType = 'general';
  String _adjustmentType = 'percentage'; // 'percentage' or 'amount'
  String _productTarget = 'all'; // 'all', 'foliar_fertilizer', 'root_fertilizer'
  String _agentTarget = 'all'; // 'all', 'agent_1', 'agent_2', 'sales_rep_group', 'specific'
  bool _isIncrease = true;

  List<String> _selectedAgentIds = [];
  List<String> _excludedAgentIds = [];

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  bool get _isAdmin {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated && authState.user.role == 'admin';
  }

  String get _currentUserRole {
    final authState = context.read<AuthBloc>().state;
    return (authState is AuthAuthenticated) ? authState.user.role : '';
  }

  String? get _currentUserId {
    final authState = context.read<AuthBloc>().state;
    return (authState is AuthAuthenticated) ? authState.user.id : null;
  }

  String? get _currentUserName {
    final authState = context.read<AuthBloc>().state;
    return (authState is AuthAuthenticated)
        ? (authState.user.displayName ?? authState.user.email)
        : null;
  }

  void _onSubmitPressed() {
    if (!_formKey.currentState!.validate()) return;

    final cubit = context.read<PriceAdjustmentCubit>();
    final String cleanValue = _valueController.text.replaceAll('.', '');
    final double rawValue = double.tryParse(cleanValue) ?? 0;

    if (rawValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập giá trị lớn hơn 0')),
      );
      return;
    }

    if (_agentTarget == 'specific' && _selectedAgentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 đại lý')),
      );
      return;
    }

    final double adjustmentValue = _isIncrease ? rawValue : -rawValue;

    // Tìm tên các đại lý đã chọn/loại trừ
    final allAgents = cubit.state.allAgents;
    final selectedNames = _selectedAgentIds.map((id) {
      final agent = allAgents.firstWhere((a) => a.id == id, orElse: () => allAgents.first);
      return agent.displayName ?? agent.email ?? id;
    }).toList();
    final excludedNames = _excludedAgentIds.map((id) {
      final agent = allAgents.firstWhere((a) => a.id == id, orElse: () => allAgents.first);
      return agent.displayName ?? agent.email ?? id;
    }).toList();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận điều chỉnh giá'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConfirmRow('Loại giá:', _getPriceTypeText()),
              _buildConfirmRow('Hình thức:', _isIncrease ? '⬆ Nâng giá' : '⬇ Hạ giá'),
              _buildConfirmRow('Giá trị:',
                  _adjustmentType == 'percentage'
                      ? '$rawValue%'
                      : '${_formatter.format(rawValue)} VND'),
              _buildConfirmRow('Sản phẩm:', _getProductTargetText()),
              _buildConfirmRow('Đại lý:', _getAgentTargetText()),
              if (_excludedAgentIds.isNotEmpty)
                _buildConfirmRow('Loại trừ:', '${excludedNames.length} đại lý'),
              const Divider(),
              if (!_isAdmin)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Yêu cầu sẽ được gửi đến Admin để duyệt.',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (_isAdmin) {
                cubit.adjustBulkPrices(
                  priceType: _priceType,
                  adjustmentType: _adjustmentType,
                  adjustmentValue: adjustmentValue,
                  productTarget: _productTarget,
                  agentTarget: _agentTarget,
                  salesRepId: _agentTarget == 'sales_rep_group' ? _currentUserId : null,
                  specificAgentIds: _agentTarget == 'specific' ? _selectedAgentIds : null,
                  excludedAgentIds: _excludedAgentIds.isNotEmpty ? _excludedAgentIds : null,
                );
              } else {
                cubit.submitBulkPriceRequest(
                  priceType: _priceType,
                  adjustmentType: _adjustmentType,
                  adjustmentValue: adjustmentValue,
                  productTarget: _productTarget,
                  agentTarget: _agentTarget,
                  salesRepId: _agentTarget == 'sales_rep_group' ? _currentUserId : null,
                  salesRepName: _agentTarget == 'sales_rep_group' ? _currentUserName : null,
                  specificAgentIds: _agentTarget == 'specific' ? _selectedAgentIds : null,
                  specificAgentNames: _agentTarget == 'specific' ? selectedNames : null,
                  excludedAgentIds: _excludedAgentIds.isNotEmpty ? _excludedAgentIds : null,
                  excludedAgentNames: excludedNames.isNotEmpty ? excludedNames : null,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isAdmin ? Colors.red : AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: Text(_isAdmin ? 'Áp dụng ngay' : 'Gửi yêu cầu duyệt'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  String _getPriceTypeText() {
    switch (_priceType) {
      case 'general': return 'Giá chung (niêm yết)';
      case 'special_adjust': return 'Giá riêng (điều chỉnh giá hiện có)';
      case 'special_from_general': return 'Giá riêng (tạo mới từ giá chung)';
      default: return '';
    }
  }

  String _getProductTargetText() {
    switch (_productTarget) {
      case 'all': return 'Toàn bộ mặt hàng';
      case 'foliar_fertilizer': return 'Phân bón lá';
      case 'root_fertilizer': return 'Phân bón gốc';
      default: return '';
    }
  }

  String _getAgentTargetText() {
    switch (_agentTarget) {
      case 'all': return 'Tất cả đại lý (Cấp 1 & 2)';
      case 'agent_1': return 'Chỉ Đại lý cấp 1';
      case 'agent_2': return 'Chỉ Đại lý cấp 2';
      case 'sales_rep_group': return 'Nhóm đại lý của tôi';
      case 'specific': return '${_selectedAgentIds.length} đại lý cụ thể';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điều chỉnh giá hàng loạt'),
      ),
      body: BlocConsumer<PriceAdjustmentCubit, PriceAdjustmentState>(
        listener: (context, state) {
          if (state.status == PriceAdjustmentStatus.success && state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.successMessage!), backgroundColor: Colors.green),
            );
            _valueController.clear();
          } else if (state.status == PriceAdjustmentStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state.status == PriceAdjustmentStatus.loading;
          final isSalesRep = _currentUserRole == 'sales_rep';

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 40.0 + MediaQuery.of(context).padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- THÔNG BÁO PHÂN QUYỀN ---
                  if (!_isAdmin)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Bạn đang tạo yêu cầu điều chỉnh giá. Admin sẽ xem xét và duyệt trước khi áp dụng.',
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // --- 1. LOẠI GIÁ ---
                  _buildSectionTitle('1. Loại giá cần điều chỉnh'),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('Giá chung (niêm yết)'),
                          subtitle: const Text('Thay đổi giá bán cho toàn bộ hệ thống', style: TextStyle(fontSize: 11)),
                          value: 'general',
                          groupValue: _priceType,
                          onChanged: isLoading ? null : (val) => setState(() => _priceType = val!),
                          dense: true,
                        ),
                        const Divider(height: 0),
                        RadioListTile<String>(
                          title: const Text('Giá riêng - Điều chỉnh giá đã có'),
                          subtitle: const Text('Nâng/hạ giá riêng đã thiết lập cho đại lý', style: TextStyle(fontSize: 11)),
                          value: 'special_adjust',
                          groupValue: _priceType,
                          onChanged: isLoading ? null : (val) => setState(() => _priceType = val!),
                          dense: true,
                        ),
                        const Divider(height: 0),
                        RadioListTile<String>(
                          title: const Text('Giá riêng - Tạo mới từ giá chung'),
                          subtitle: const Text('Lấy giá chung làm cơ sở rồi nâng/hạ thành giá riêng', style: TextStyle(fontSize: 11)),
                          value: 'special_from_general',
                          groupValue: _priceType,
                          onChanged: isLoading ? null : (val) => setState(() => _priceType = val!),
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- 2. HÌNH THỨC ---
                  _buildSectionTitle('2. Hình thức điều chỉnh'),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('Nâng giá'),
                          value: true,
                          groupValue: _isIncrease,
                          onChanged: isLoading ? null : (val) => setState(() => _isIncrease = val!),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('Hạ giá'),
                          value: false,
                          groupValue: _isIncrease,
                          onChanged: isLoading ? null : (val) => setState(() => _isIncrease = val!),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- 3. LOẠI ĐIỀU CHỈNH ---
                  _buildSectionTitle('3. Loại điều chỉnh'),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Phần trăm (%)'),
                          value: 'percentage',
                          groupValue: _adjustmentType,
                          onChanged: isLoading ? null : (val) {
                            setState(() {
                              _adjustmentType = val!;
                              _valueController.clear();
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Số tiền (VND)'),
                          value: 'amount',
                          groupValue: _adjustmentType,
                          onChanged: isLoading ? null : (val) {
                            setState(() {
                              _adjustmentType = val!;
                              _valueController.clear();
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- 4. GIÁ TRỊ ---
                  _buildSectionTitle('4. Giá trị điều chỉnh'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _valueController,
                    keyboardType: TextInputType.number,
                    enabled: !isLoading,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      if (_adjustmentType == 'amount') ThousandsSeparatorInputFormatter(),
                    ],
                    decoration: InputDecoration(
                      labelText: _adjustmentType == 'percentage' ? 'Nhập số phần trăm' : 'Nhập số tiền (VND)',
                      hintText: _adjustmentType == 'percentage' ? 'VD: 5' : 'VD: 10.000',
                      border: const OutlineInputBorder(),
                      suffixText: _adjustmentType == 'percentage' ? '%' : 'VND',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Vui lòng nhập giá trị';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // --- 5. ĐỐI TƯỢNG SẢN PHẨM ---
                  _buildSectionTitle('5. Đối tượng sản phẩm'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _productTarget,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tất cả sản phẩm')),
                      DropdownMenuItem(value: 'foliar_fertilizer', child: Text('Phân bón lá')),
                      DropdownMenuItem(value: 'root_fertilizer', child: Text('Phân bón gốc')),
                    ],
                    onChanged: isLoading ? null : (val) => setState(() => _productTarget = val!),
                  ),
                  const SizedBox(height: 24),

                  // --- 6. ĐỐI TƯỢNG ĐẠI LÝ ---
                  _buildSectionTitle('6. Đối tượng đại lý'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _agentTarget,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('Tất cả đại lý (Cấp 1 & 2)')),
                      const DropdownMenuItem(value: 'agent_1', child: Text('Chỉ Đại lý cấp 1')),
                      const DropdownMenuItem(value: 'agent_2', child: Text('Chỉ Đại lý cấp 2')),
                      if (isSalesRep)
                        const DropdownMenuItem(value: 'sales_rep_group', child: Text('Nhóm đại lý của tôi')),
                      if (_priceType != 'general') // Chọn cụ thể chỉ cho giá riêng
                        const DropdownMenuItem(value: 'specific', child: Text('Chọn đại lý cụ thể...')),
                    ],
                    onChanged: isLoading ? null : (val) {
                      setState(() {
                        _agentTarget = val!;
                        _selectedAgentIds = [];
                        _excludedAgentIds = [];
                      });
                    },
                  ),

                  // --- CHỌN ĐẠI LÝ CỤ THỂ ---
                  if (_agentTarget == 'specific') ...[
                    const SizedBox(height: 12),
                    _buildAgentSelector(
                      title: 'Chọn đại lý áp dụng',
                      agents: state.allAgents,
                      selectedIds: _selectedAgentIds,
                      isLoading: state.isLoadingAgents,
                      onChanged: (ids) => setState(() => _selectedAgentIds = ids),
                    ),
                  ],

                  // --- LOẠI TRỪ ĐẠI LÝ ---
                  if (_agentTarget != 'specific') ...[
                    const SizedBox(height: 16),
                    _buildSectionTitle('7. Loại trừ đại lý (tùy chọn)'),
                    const SizedBox(height: 4),
                    Text(
                      'Đại lý bị loại trừ sẽ giữ nguyên giá hiện tại',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 8),
                    _buildAgentSelector(
                      title: 'Loại trừ đại lý',
                      agents: _getExcludableAgents(state),
                      selectedIds: _excludedAgentIds,
                      isLoading: state.isLoadingAgents,
                      onChanged: (ids) => setState(() => _excludedAgentIds = ids),
                      isExclusion: true,
                    ),
                  ],

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _onSubmitPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAdmin
                            ? (_isIncrease ? Colors.green : Colors.red)
                            : AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isAdmin ? 'Áp dụng điều chỉnh giá' : 'Gửi yêu cầu duyệt',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<UserModel> _getExcludableAgents(PriceAdjustmentState state) {
    if (_agentTarget == 'sales_rep_group') return state.salesRepAgents;
    if (_agentTarget == 'agent_1') return state.allAgents.where((a) => a.role == 'agent_1').toList();
    if (_agentTarget == 'agent_2') return state.allAgents.where((a) => a.role == 'agent_2').toList();
    return state.allAgents;
  }

  Widget _buildAgentSelector({
    required String title,
    required List<UserModel> agents,
    required List<String> selectedIds,
    required bool isLoading,
    required ValueChanged<List<String>> onChanged,
    bool isExclusion = false,
  }) {
    if (isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ));
    }

    if (agents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Không có đại lý nào.', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chips hiển thị đại lý đã chọn
        if (selectedIds.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: selectedIds.map((id) {
              final agent = agents.firstWhere((a) => a.id == id, orElse: () => agents.first);
              return Chip(
                label: Text(
                  agent.displayName ?? agent.email ?? id,
                  style: const TextStyle(fontSize: 12),
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  onChanged(List.from(selectedIds)..remove(id));
                },
                backgroundColor: isExclusion ? Colors.red.shade50 : Colors.green.shade50,
                side: BorderSide(color: isExclusion ? Colors.red.shade200 : Colors.green.shade200),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
        // Nút thêm
        OutlinedButton.icon(
          icon: Icon(isExclusion ? Icons.person_off_outlined : Icons.person_add_outlined, size: 18),
          label: Text(
            isExclusion ? 'Chọn đại lý loại trừ...' : 'Chọn đại lý...',
            style: const TextStyle(fontSize: 13),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: isExclusion ? Colors.red : AppTheme.primaryGreen,
          ),
          onPressed: () => _showAgentPickerDialog(
            agents: agents,
            selectedIds: selectedIds,
            onChanged: onChanged,
            isExclusion: isExclusion,
          ),
        ),
      ],
    );
  }

  void _showAgentPickerDialog({
    required List<UserModel> agents,
    required List<String> selectedIds,
    required ValueChanged<List<String>> onChanged,
    bool isExclusion = false,
  }) {
    final tempSelected = List<String>.from(selectedIds);
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final query = searchController.text.toLowerCase();
            final filteredAgents = agents.where((a) {
              final name = (a.displayName ?? '').toLowerCase();
              final email = (a.email ?? '').toLowerCase();
              return name.contains(query) || email.contains(query);
            }).toList();

            return AlertDialog(
              title: Text(isExclusion ? 'Chọn đại lý loại trừ' : 'Chọn đại lý'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Tìm kiếm đại lý...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => setStateDialog(() {}),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${tempSelected.length} đã chọn', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        TextButton(
                          onPressed: () {
                            setStateDialog(() {
                              if (tempSelected.length == filteredAgents.length) {
                                tempSelected.clear();
                              } else {
                                tempSelected.clear();
                                tempSelected.addAll(filteredAgents.map((a) => a.id));
                              }
                            });
                          },
                          child: Text(
                            tempSelected.length == filteredAgents.length ? 'Bỏ chọn tất cả' : 'Chọn tất cả',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 4),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredAgents.length,
                        itemBuilder: (_, index) {
                          final agent = filteredAgents[index];
                          final isSelected = tempSelected.contains(agent.id);
                          return CheckboxListTile(
                            value: isSelected,
                            dense: true,
                            title: Text(
                              agent.displayName ?? 'Chưa có tên',
                              style: const TextStyle(fontSize: 13),
                            ),
                            subtitle: Text(
                              '${agent.role == 'agent_1' ? 'Cấp 1' : 'Cấp 2'} • ${agent.email ?? ''}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            onChanged: (val) {
                              setStateDialog(() {
                                if (val == true) {
                                  tempSelected.add(agent.id);
                                } else {
                                  tempSelected.remove(agent.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    onChanged(List.from(tempSelected));
                    Navigator.pop(dialogContext);
                  },
                  child: Text('Xác nhận (${tempSelected.length})'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    final String cleanValue = newValue.text.replaceAll('.', '');
    final double value = double.parse(cleanValue);

    final formatter = NumberFormat.decimalPattern('vi_VN');
    final String newText = formatter.format(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
