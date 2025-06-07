import 'package:flutter/material.dart';

class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({super.key});

  static PageRoute<void> route() {
    // Sử dụng fullscreenDialog: true để trang này trượt lên từ dưới
    return MaterialPageRoute<void>(
      builder: (_) => const OrderSuccessPage(),
      fullscreenDialog: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Không có nút back tự động vì là fullscreenDialog
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 100,
                color: Colors.green.shade600,
              ),
              const SizedBox(height: 24),
              Text(
                'Đặt hàng thành công!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Cảm ơn bạn đã mua sắm. Đơn hàng của bạn đang được xử lý và sẽ sớm được giao đến bạn.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Quay về trang chủ, xóa tất cả các trang khác khỏi stack
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('QUAY VỀ TRANG CHỦ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
