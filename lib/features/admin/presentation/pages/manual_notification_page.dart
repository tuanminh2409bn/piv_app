// lib/features/admin/presentation/pages/manual_notification_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:piv_app/data/models/user_model.dart';

// Model đơn giản để chứa thông tin NVKD
class SalesRep {
  final String id;
  final String name;
  SalesRep({required this.id, required this.name});
}

enum TargetMode { all, salesGroup, specific }

class ManualNotificationPage extends StatefulWidget {
  const ManualNotificationPage({super.key});

  @override
  State<ManualNotificationPage> createState() => _ManualNotificationPageState();
}

class _ManualNotificationPageState extends State<ManualNotificationPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  List<SalesRep> _salesReps = [];
  SalesRep? _selectedSalesRep;
  
  // --- THÊM MỚI ---
  TargetMode _targetMode = TargetMode.all;
  List<UserModel> _allAgents = [];
  List<UserModel> _selectedAgents = [];
  bool _isLoadingAgents = false;
  // ----------------

  @override
  void initState() {
    super.initState();
    _fetchSalesReps();
    _fetchAllAgents(); // Tải sẵn danh sách đại lý
  }

  Future<void> _fetchSalesReps() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'sales_rep')
          .get();

      final reps = snapshot.docs
          .map((doc) => SalesRep(id: doc.id, name: doc.data()['displayName'] ?? 'Chưa có tên'))
          .toList();

      if (mounted) setState(() => _salesReps = reps);
    } catch (e) {
      debugPrint('Lỗi tải danh sách NVKD: $e');
    }
  }

  Future<void> _fetchAllAgents() async {
    setState(() => _isLoadingAgents = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['agent_1', 'agent_2'])
          .where('status', isEqualTo: 'active')
          .get();
      
      final agents = snapshot.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
      if (mounted) setState(() => _allAgents = agents);
    } catch (e) {
      debugPrint('Lỗi tải danh sách đại lý: $e');
    } finally {
      if (mounted) setState(() => _isLoadingAgents = false);
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate danh sách người nhận
    if (_targetMode == TargetMode.specific && _selectedAgents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một đại lý'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_targetMode == TargetMode.salesGroup && _selectedSalesRep == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn nhóm NVKD'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');
      final callable = functions.httpsCallable('sendManualNotification');

      // Chuẩn bị dữ liệu gửi đi
      final Map<String, dynamic> data = {
        'title': _titleController.text,
        'body': _bodyController.text,
      };

      if (_targetMode == TargetMode.salesGroup) {
        data['salesRepId'] = _selectedSalesRep!.id;
      } else if (_targetMode == TargetMode.specific) {
        data['userIds'] = _selectedAgents.map((u) => u.id).toList();
      }
      // Nếu là TargetMode.all thì không gửi salesRepId hay userIds

      final result = await callable.call<Map<String, dynamic>>(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.data['message'] ?? 'Gửi thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        _titleController.clear();
        _bodyController.clear();
        setState(() {
          _selectedAgents.clear();
          _targetMode = TargetMode.all;
          _selectedSalesRep = null;
        });
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.message ?? 'Đã có lỗi xảy ra.'}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi không xác định: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAgentSelectionDialog() async {
    final selected = await showDialog<List<UserModel>>(
      context: context,
      builder: (ctx) => _AgentSelectionDialog(
        allAgents: _allAgents,
        initialSelected: _selectedAgents,
      ),
    );

    if (selected != null) {
      setState(() => _selectedAgents = selected);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gửi Thông Báo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTargetSelection(),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề',
                  hintText: 'VD: Thông báo công nợ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập tiêu đề' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'Nội dung thông báo',
                  hintText: 'VD: Quý khách vui lòng thanh toán công nợ...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message_outlined),
                ),
                maxLines: 5,
                validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập nội dung' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendNotification,
                icon: _isLoading
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send),
                label: Text(_isLoading ? 'Đang gửi...' : 'Gửi Thông Báo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetSelection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gửi đến:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            RadioListTile<TargetMode>(
              title: const Text('Tất cả Đại lý'),
              value: TargetMode.all,
              groupValue: _targetMode,
              onChanged: (val) => setState(() => _targetMode = val!),
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<TargetMode>(
              title: const Text('Theo nhóm NVKD quản lý'),
              value: TargetMode.salesGroup,
              groupValue: _targetMode,
              onChanged: (val) => setState(() => _targetMode = val!),
              contentPadding: EdgeInsets.zero,
            ),
            if (_targetMode == TargetMode.salesGroup)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: DropdownButtonFormField<SalesRep?>(
                  value: _selectedSalesRep,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    hintText: 'Chọn NVKD',
                    isDense: true,
                  ),
                  items: _salesReps.map((rep) {
                    return DropdownMenuItem<SalesRep?>(
                      value: rep,
                      child: Text(rep.name),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedSalesRep = value),
                ),
              ),
            RadioListTile<TargetMode>(
              title: const Text('Chọn Đại lý cụ thể'),
              value: TargetMode.specific,
              groupValue: _targetMode,
              onChanged: (val) => setState(() => _targetMode = val!),
              contentPadding: EdgeInsets.zero,
            ),
            if (_targetMode == TargetMode.specific) ...[
              if (_isLoadingAgents)
                const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
              else ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showAgentSelectionDialog,
                        icon: const Icon(Icons.person_add_alt_1, size: 18),
                        label: Text('Chọn Đại Lý (${_selectedAgents.length})'),
                        style: ElevatedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      if (_selectedAgents.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(() => _selectedAgents.clear()),
                          child: const Text('Xóa chọn', style: TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                ),
                if (_selectedAgents.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 16, top: 8),
                    constraints: const BoxConstraints(maxHeight: 150),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _selectedAgents.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final agent = _selectedAgents[index];
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          title: Text(agent.displayName ?? 'Unknown'),
                          subtitle: Text((agent.addresses.isNotEmpty ? agent.addresses.first.phoneNumber : null) ?? agent.email ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              setState(() {
                                _selectedAgents.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// Dialog chọn nhiều người dùng có chức năng tìm kiếm
class _AgentSelectionDialog extends StatefulWidget {
  final List<UserModel> allAgents;
  final List<UserModel> initialSelected;

  const _AgentSelectionDialog({required this.allAgents, required this.initialSelected});

  @override
  State<_AgentSelectionDialog> createState() => _AgentSelectionDialogState();
}

class _AgentSelectionDialogState extends State<_AgentSelectionDialog> {
  late List<UserModel> _filteredAgents;
  late List<UserModel> _tempSelected;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredAgents = widget.allAgents;
    _tempSelected = List.from(widget.initialSelected);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAgents = widget.allAgents.where((agent) {
        final name = (agent.displayName ?? '').toLowerCase();
        final phone = (agent.addresses.isNotEmpty ? agent.addresses.first.phoneNumber : '').toLowerCase();
        return name.contains(query) || phone.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(UserModel agent) {
    setState(() {
      if (_tempSelected.any((u) => u.id == agent.id)) {
        _tempSelected.removeWhere((u) => u.id == agent.id);
      } else {
        _tempSelected.add(agent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: double.maxFinite,
        height: 600, // Fixed height for consistency
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Chọn Đại Lý (${_tempSelected.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Tìm theo tên hoặc SĐT...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredAgents.length,
                itemBuilder: (context, index) {
                  final agent = _filteredAgents[index];
                  final isSelected = _tempSelected.any((u) => u.id == agent.id);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(agent),
                    title: Text(agent.displayName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(
                      '${(agent.addresses.isNotEmpty ? agent.addresses.first.phoneNumber : null) ?? 'No Phone'} • ${agent.role == 'agent_1' ? 'Cấp 1' : 'Cấp 2'}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    secondary: CircleAvatar(
                      backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
                      child: Text(
                        (agent.displayName?[0] ?? 'A').toUpperCase(),
                        style: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_tempSelected),
                    child: const Text('Xác nhận'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}