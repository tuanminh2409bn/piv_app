import 'package:flutter/material.dart';
import 'package:piv_app/features/orders/presentation/pages/order_detail_page.dart';

class OrderSuccessPage extends StatelessWidget {
  final String orderId; // <<< NHẬN ORDER ID

  const OrderSuccessPage({super.key, required this.orderId});

  static PageRoute<void> route({required String orderId}) {
    return MaterialPageRoute<void>(
      builder: (_) => OrderSuccessPage(orderId: orderId),
      fullscreenDialog: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
              const Text(
                'Chiết khấu (nếu có) sẽ được tự động tính toán. Bạn có thể xem chi tiết trong đơn hàng của mình.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // <<< NÚT XEM CHI TIẾT MỚI >>>
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                        OrderDetailPage.route(orderId),
                            (route) => route.isFirst
                    );
                  },
                  child: const Text('XEM CHI TIẾT ĐƠN HÀNG'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('VỀ TRANG CHỦ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}