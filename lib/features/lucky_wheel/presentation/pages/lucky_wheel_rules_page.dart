// lib/features/lucky_wheel/presentation/pages/lucky_wheel_rules_page.dart

import 'package:flutter/material.dart';

class LuckyWheelRulesPage extends StatelessWidget {
  const LuckyWheelRulesPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const LuckyWheelRulesPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thể Lệ Chương Trình'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'I. Tên chương trình'),
            _buildContentText('Vòng Quay May Mắn PIV.'),
            const SizedBox(height: 24),

            _buildSectionTitle(context, 'II. Thời gian diễn ra'),
            _buildContentText(
                'Sẽ có thông báo khi chương trình diễn ra.'
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(context, 'III. Đối tượng tham gia'),
            _buildContentText(
                'Tất cả các đại lý cấp 1 và cấp 2 có tài khoản đang hoạt động trên ứng dụng PIV App.'
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(context, 'IV. Cách thức nhận lượt quay'),
            _buildContentText(
                    '- Mỗi ngày đăng nhập vào ứng dụng sẽ nhận được 1 lượt quay miễn phí.\n'
                    '- Với mỗi đơn hàng hoàn thành có giá trị 10.000.000 đồng, bạn sẽ nhận được 1 lượt quay.\n'
                    '- Các lượt quay sẽ được cộng dồn và không có giá trị quy đổi thành tiền mặt.'
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(context, 'V. Cơ cấu giải thưởng'),
            _buildContentText(
                '// BẠN HÃY LIỆT KÊ CÁC PHẦN THƯỞNG CÓ TRONG VÒNG QUAY.\n'
                    '// Ví dụ:\n'
                    '- Giải nhất: 01 chỉ vàng SJC 9999.\n'
                    '- Giải nhì: 01 thùng bia Heineken.\n'
                    '- Giải ba: 01 voucher 500.000 đồng.\n'
                    '- Giải khuyến khích: Chúc bạn may mắn lần sau.'
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(context, 'VI. Quy định chung'),
            _buildContentText(
                    '- Trong mọi trường hợp, quyết định của PIV là quyết định cuối cùng.\n'
                    '- PIV có quyền thay đổi thể lệ chương trình mà không cần báo trước.\n'
                    '- Mọi hành vi gian lận sẽ bị hủy kết quả và có thể dẫn đến khóa tài khoản.'
            ),
            const SizedBox(height: 32),

            // ========== PHẦN QUAN TRỌNG NHẤT CHO APPLE ==========
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildContentText(
                'Tuyên bố miễn trừ trách nhiệm: Apple không phải là nhà tài trợ và không tham gia vào chương trình khuyến mãi này dưới bất kỳ hình thức nào.',
                isBold: true,
              ),
            ),
            // =======================================================

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildContentText(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          height: 1.5,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}