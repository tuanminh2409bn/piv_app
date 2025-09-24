// lib/features/returns/presentation/pages/create_return_request_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/features/returns/presentation/bloc/create_return_request_cubit.dart';

class CreateReturnRequestPage extends StatelessWidget {
  final OrderModel order;
  const CreateReturnRequestPage({super.key, required this.order});

  static PageRoute<void> route(OrderModel order) {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (_) => sl<CreateReturnRequestCubit>(),
        child: CreateReturnRequestPage(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const CreateReturnRequestView();
  }
}

class CreateReturnRequestView extends StatefulWidget {
  const CreateReturnRequestView({super.key});

  @override
  State<CreateReturnRequestView> createState() => _CreateReturnRequestViewState();
}

class _CreateReturnRequestViewState extends State<CreateReturnRequestView> {
  final _notesController = TextEditingController();
  String _selectedReason = 'Sản phẩm bị hỏng/vỡ'; // Giá trị mặc định

  final List<String> _reasons = [
    'Sản phẩm bị hỏng/vỡ',
    'Giao sai sản phẩm',
    'Sản phẩm hết hạn sử dụng',
    'Không đúng như mô tả',
    'Lý do khác'
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = (context.findAncestorWidgetOfExactType<CreateReturnRequestPage>())!.order;

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo yêu cầu Đổi/Trả')),
      body: BlocConsumer<CreateReturnRequestCubit, CreateReturnRequestState>(
        listener: (context, state) {
          if (state.status == CreateReturnRequestStatus.error) {
            ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
            );
          } else if (state.status == CreateReturnRequestStatus.success) {
            showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  title: const Text('Thành công'),
                  content: const Text('Yêu cầu của bạn đã được gửi đi. Công ty sẽ sớm xem xét và phản hồi.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(); // Đóng dialog
                        Navigator.of(context).pop(); // Quay về trang chi tiết đơn hàng
                      },
                      child: const Text('ĐÓNG'),
                    )
                  ],
                )
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, '1. Chọn sản phẩm cần đổi/trả'),
                _buildProductSelectionList(context, order, state),
                const SizedBox(height: 24),

                _buildSectionTitle(context, '2. Lý do đổi/trả'),
                _buildReasonDropdown(context),
                const SizedBox(height: 24),

                _buildSectionTitle(context, '3. Cung cấp bằng chứng (ảnh)'),
                _buildImagePicker(context, state),
                const SizedBox(height: 24),

                _buildSectionTitle(context, '4. Ghi chú (tùy chọn)'),
                _buildNotesField(context),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.status == CreateReturnRequestStatus.submitting
                        ? null
                        : () => context.read<CreateReturnRequestCubit>().submitRequest(
                      order: order,
                      reason: _selectedReason,
                      userNotes: _notesController.text.trim(),
                    ),
                    child: state.status == CreateReturnRequestStatus.submitting
                        ? const CircularProgressIndicator()
                        : const Text('GỬI YÊU CẦU'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildProductSelectionList(BuildContext context, OrderModel order, CreateReturnRequestState state) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: order.items.length,
      itemBuilder: (context, index) {
        final item = order.items[index];
        final isSelected = state.selectedItems.contains(item);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (bool? value) {
              context.read<CreateReturnRequestCubit>().toggleItemSelection(item);
            },
            secondary: Image.network(item.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
            title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Số lượng: ${item.quantity}'),
          ),
        );
      },
    );
  }

  Widget _buildReasonDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedReason,
          items: _reasons.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedReason = newValue!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context, CreateReturnRequestState state) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: state.images.map((imageFile) {
            return Stack(
              children: [
                Image.file(imageFile, width: 80, height: 80, fit: BoxFit.cover),
                Positioned(
                  top: -10,
                  right: -10,
                  child: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => context.read<CreateReturnRequestCubit>().removeImage(imageFile),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // --- THAY ĐỔI: Sửa lại các thuộc tính của DottedBorder ---
        DottedBorder(
          color: Colors.grey,
          strokeWidth: 1,
          dashPattern: const [6, 3],
          borderType: BorderType.RRect,
          radius: const Radius.circular(12),
          child: InkWell(
            onTap: () => context.read<CreateReturnRequestCubit>().pickImages(),
            child: Container(
              height: 100,
              width: double.infinity,
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 40),
                  SizedBox(height: 4),
                  Text('Thêm ảnh'),
                ],
              ),
            ),
          ),
        )
        // --- KẾT THÚC THAY ĐỔI ---
      ],
    );
  }

  Widget _buildNotesField(BuildContext context) {
    return TextFormField(
      controller: _notesController,
      maxLines: 4,
      decoration: const InputDecoration(
        hintText: 'Mô tả thêm về vấn đề của bạn...',
        border: OutlineInputBorder(),
      ),
    );
  }
}