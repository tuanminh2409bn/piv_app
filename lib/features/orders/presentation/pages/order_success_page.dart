//lib/features/orders/presentation/pages/order_success_page.dart

import 'package:flutter/material.dart';
import 'package:piv_app/common/widgets/responsive_wrapper.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/core/utils/responsive.dart';
import 'package:piv_app/features/orders/presentation/pages/order_detail_page.dart';

class OrderSuccessPage extends StatelessWidget {
  final String orderId;

  const OrderSuccessPage({super.key, required this.orderId});

  static PageRoute<void> route({required String orderId}) {
    return MaterialPageRoute<void>(
      builder: (_) => OrderSuccessPage(orderId: orderId),
      fullscreenDialog: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ResponsiveWrapper(
        maxWidth: 600, // Giới hạn chiều rộng cho trang thành công để tập trung hơn
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 100,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Đặt hàng thành công!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chiết khấu (nếu có) sẽ được tự động tính toán.\nBạn có thể theo dõi trạng thái đơn hàng trong phần quản lý.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 48),

                // Nhóm nút điều hướng
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    SizedBox(
                      width: isDesktop ? 250 : double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                              OrderDetailPage.route(orderId),
                                  (route) => route.isFirst
                          );
                        },
                        child: const Text('XEM CHI TIẾT ĐƠN HÀNG', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(
                      width: isDesktop ? 250 : double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          side: const BorderSide(color: AppTheme.primaryGreen),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        child: const Text('VỀ TRANG CHỦ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}