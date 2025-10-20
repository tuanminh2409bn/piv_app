// lib/features/returns/presentation/pages/create_return_request_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/order_item_model.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/features/returns/presentation/bloc/create_return_request_cubit.dart';
import 'package:intl/intl.dart';

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
  String _selectedReason = 'Sản phẩm bị hỏng/vỡ';

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

  double _calculatedPenalty = 0.0;
  String _policyMessage = '';

  void _calculatePenalty(OrderModel order, CreateReturnRequestState state) {
    if (order.createdAt == null) {
      setState(() {
        _calculatedPenalty = 0.0;
        _policyMessage = 'Không thể xác định ngày tạo đơn hàng.';
      });
      return;
    }

    final daysDifference = DateTime.now().difference(order.createdAt!.toDate()).inDays;
    final monthsDifference = daysDifference / 30;

    double penaltyPerCrate = 0;
    if (monthsDifference > 24) {
      _policyMessage = 'Đơn hàng đã quá 24 tháng, có thể không được đổi trả.';
      penaltyPerCrate = 0; // Hoặc một giá trị cấm
    } else if (monthsDifference > 12) {
      _policyMessage = 'Phí phạt dự kiến: 300.000 đ/thùng';
      penaltyPerCrate = 300000;
    } else if (monthsDifference > 3) {
      _policyMessage = 'Phí phạt dự kiến: 150.000 đ/thùng';
      penaltyPerCrate = 150000;
    } else {
      _policyMessage = 'Miễn phí đổi trả trong 3 tháng đầu.';
      penaltyPerCrate = 0;
    }

    if (penaltyPerCrate == 0) {
      setState(() => _calculatedPenalty = 0.0);
      return;
    }

    double totalCratesToReturn = 0;
    state.returnedItems.forEach((productId, returnedQuantity) {
      if (returnedQuantity > 0) {
        final originalItem = order.items.firstWhere((item) => item.productId == productId);
        // Làm tròn lên để đảm bảo 1 chai cũng tính là 1 thùng
        final crates = (returnedQuantity / originalItem.quantityPerPackage).ceil();
        totalCratesToReturn += crates;
      }
    });

    setState(() {
      _calculatedPenalty = totalCratesToReturn * penaltyPerCrate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final order = (context.findAncestorWidgetOfExactType<CreateReturnRequestPage>())!.order;

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo yêu cầu Đổi/Trả')),
      body: BlocConsumer<CreateReturnRequestCubit, CreateReturnRequestState>(
        listenWhen: (previous, current) {
          // Chỉ lắng nghe khi số lượng item thay đổi
          if (previous.returnedItems != current.returnedItems) return true;
          // Hoặc khi trạng thái submit thay đổi
          if (previous.status != current.status && (current.status == CreateReturnRequestStatus.error || current.status == CreateReturnRequestStatus.success)) return true;
          return false;
        },
        listener: (context, state) {
          // --- GỘP LOGIC LẠI LÀM MỘT ---

          // 1. Tính toán lại phí khi số lượng thay đổi
          // (Chúng ta gọi hàm này trong listenWhen, nhưng gọi ở đây cũng đảm bảo an toàn)
          _calculatePenalty(order, state);

          // 2. Xử lý kết quả submit
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
                _buildPolicyInfo(context),
                const SizedBox(height: 24),
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
                      penaltyFee: _calculatedPenalty,
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

  Widget _buildPolicyInfo(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Giữ căn lề trái cho toàn bộ cột
        children: [
          Text(
            'Quy Chế Đổi Trả',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
          ),
          const SizedBox(height: 8),
          const Text('• Miễn phí đổi trả trong 3 tháng đầu.\n'
              '• Phạt 150.000 đ/thùng từ 3-12 tháng.\n'
              '• Phạt 300.000 đ/thùng từ 12-24 tháng.\n'
              '• Sau 24 tháng, yêu cầu có thể bị từ chối.'),
          const Divider(height: 20, thickness: 1),

          // --- THAY ĐỔI TỪ ROW THÀNH COLUMN ---
          // Hiển thị thông báo về mức phạt
          Text(
            _policyMessage,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
          // Thêm khoảng cách nhỏ nếu có phí phạt
          if (_calculatedPenalty > 0) const SizedBox(height: 4),
          // Hiển thị số tiền phạt (luôn hiển thị, kể cả 0đ)
          Align( // Căn phải số tiền cho đẹp
            alignment: Alignment.centerRight,
            child: Text(
              formatter.format(_calculatedPenalty),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                // Màu đỏ nếu có phí, màu xanh nếu miễn phí
                color: _calculatedPenalty > 0 ? Colors.red.shade700 : Colors.green.shade700,
              ),
            ),
          ),
          // --- KẾT THÚC THAY ĐỔI ---

          // Hiển thị ghi chú về trừ công nợ nếu có phí
          if (_calculatedPenalty > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4.0), // Giữ padding
              child: const Text(
                '(Phí sẽ được trừ trực tiếp vào công nợ của bạn sau khi yêu cầu được xử lý)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],
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
        final returnedQuantity = state.returnedItems[item.productId] ?? 0;
        final maxQuantity = item.quantity * item.quantityPerPackage;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          elevation: returnedQuantity > 0 ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: returnedQuantity > 0 ? Theme.of(context).primaryColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(item.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(
                            'Đã mua: ${item.packaging.contains('thùng') ? 'thùng' : item.packaging} (Tổng: $maxQuantity ${item.unit})',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildQuantitySelector(context, item, returnedQuantity, maxQuantity),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuantitySelector(BuildContext context, OrderItemModel item, int currentQuantity, int maxQuantity) {
    return Row(
      // mainAxisAlignment: MainAxisAlignment.spaceBetween, // Bỏ thuộc tính này
      children: [
        // --- THAY ĐỔI 1: Bọc Text trong Expanded ---
        // Expanded cho phép Text co dãn và chiếm hết không gian còn lại
        Expanded(
          child: Text(
            'Số lượng trả (${item.unit}):',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        // Thêm một khoảng trống nhỏ để ngăn cách
        const SizedBox(width: 8),

        // --- THAY ĐỔI 2: Tối ưu lại vùng chọn số lượng ---
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // Giúp Row chỉ chiếm không gian cần thiết
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  context.read<CreateReturnRequestCubit>().updateReturnQuantity(item, currentQuantity - 1);
                },
                splashRadius: 20,
              ),
              InkWell(
                onTap: () => _showQuantityInputDialog(context, item, currentQuantity, maxQuantity),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0), // Giảm padding ngang
                  child: Text(
                    '$currentQuantity',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  context.read<CreateReturnRequestCubit>().updateReturnQuantity(item, currentQuantity + 1);
                },
                splashRadius: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showQuantityInputDialog(
      BuildContext pageContext,
      OrderItemModel item,
      int currentQuantity,
      int maxQuantity
      ) async {
    final controller = TextEditingController(text: currentQuantity.toString());
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: pageContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Nhập số lượng trả'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Số lượng (${item.unit})',
                hintText: 'Tối đa: $maxQuantity',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số lượng';
                }
                final n = int.tryParse(value);
                if (n == null) {
                  return 'Số không hợp lệ';
                }
                if (n < 0) {
                  return 'Số lượng không thể âm';
                }
                if (n > maxQuantity) {
                  return 'Vượt quá số lượng đã mua';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('HỦY'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('XÁC NHẬN'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newQuantity = int.parse(controller.text);
                  // Sử dụng context của trang để gọi Cubit
                  pageContext.read<CreateReturnRequestCubit>().updateReturnQuantity(item, newQuantity);
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
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