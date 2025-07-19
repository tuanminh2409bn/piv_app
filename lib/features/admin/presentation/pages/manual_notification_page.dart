// lib/features/admin/presentation/pages/manual_notification_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Model đơn giản để chứa thông tin NVKD
class SalesRep {
  final String id;
  final String name;
  SalesRep({required this.id, required this.name});
}

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
  SalesRep? _selectedSalesRep; // Sẽ là null nếu chọn "Tất cả"

  @override
  void initState() {
    super.initState();
    _fetchSalesReps();
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

      setState(() {
        _salesReps = reps;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách NVKD: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');
      final callable = functions.httpsCallable('sendManualNotification');

      final result = await callable.call<Map<String, dynamic>>({
        'title': _titleController.text,
        'body': _bodyController.text,
        'salesRepId': _selectedSalesRep?.id, // Gửi ID của NVKD, hoặc null nếu chọn "Tất cả"
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.data['message'] ?? 'Gửi thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        _titleController.clear();
        _bodyController.clear();
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.message ?? 'Đã có lỗi xảy ra.'}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: const Text('Gửi Thông Báo Thủ Công'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Chọn đối tượng nhận thông báo', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // Dropdown để chọn NVKD
              DropdownButtonFormField<SalesRep?>(
                value: _selectedSalesRep,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                hint: const Text('Gửi cho tất cả Đại lý & NVKD'),
                // Thêm lựa chọn "Tất cả" vào đầu danh sách
                items: [
                  const DropdownMenuItem<SalesRep?>(
                    value: null,
                    child: Text('Tất cả Đại lý & NVKD'),
                  ),
                  ..._salesReps.map((rep) {
                    return DropdownMenuItem<SalesRep?>(
                      value: rep,
                      child: Text('Đại lý của: ${rep.name}'),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSalesRep = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề',
                  hintText: 'VD: Khuyến mãi chớp nhoáng!',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập tiêu đề' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'Nội dung thông báo',
                  hintText: 'VD: Giảm giá 50% cho tất cả các mặt hàng...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập nội dung' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendNotification,
                icon: _isLoading
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_outlined),
                label: Text(_isLoading ? 'Đang gửi...' : 'Gửi Thông Báo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}