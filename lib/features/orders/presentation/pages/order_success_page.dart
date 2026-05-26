import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:piv_app/common/widgets/responsive_wrapper.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/core/utils/responsive.dart';
import 'package:piv_app/features/orders/presentation/pages/order_detail_page.dart';
import 'package:piv_app/core/theme/nature_background_painter.dart';

class OrderSuccessPage extends StatefulWidget {
  final String orderId;

  const OrderSuccessPage({super.key, required this.orderId});

  static PageRoute<void> route({required String orderId}) {
    return MaterialPageRoute<void>(
      builder: (_) => OrderSuccessPage(orderId: orderId),
      fullscreenDialog: true,
    );
  }

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Painter
          Positioned.fill(
            child: CustomPaint(
              painter: NatureBackgroundPainter(
                color1: AppTheme.primaryGreen.withValues(alpha: 0.05),
                color2: AppTheme.secondaryGreen.withValues(alpha: 0.05),
                accent: AppTheme.accentGold.withValues(alpha: 0.1),
              ),
            ),
          ),
          
          SafeArea(
            bottom: false, // Tắt SafeArea bottom mặc định để tự kiểm soát padding
            child: Center(
              child: SingleChildScrollView(
                child: ResponsiveWrapper(
                  maxWidth: 650,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 24.0, 
                      right: 24.0, 
                      top: 24.0, 
                      bottom: 48.0 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Success Icon Animated
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            size: 100,
                            color: AppTheme.primaryGreen,
                          ),
                        )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.elasticOut)
                        .then()
                        .shimmer(duration: 1000.ms, color: Colors.white, blendMode: BlendMode.srcOver),

                        const SizedBox(height: 32),
                        
                        // Title
                        Text(
                          'Đặt hàng thành công!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                            fontSize: isDesktop ? 32 : 26,
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                        
                        const SizedBox(height: 16),
                        
                        // Order ID Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            'Mã đơn: ${widget.orderId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                              fontSize: 16,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 24),
                        
                        // Description
                        const Text(
                          'Cảm ơn bạn đã tin tưởng và mua sắm tại PIV.\nChiết khấu (nếu có) sẽ được tự động tính toán.\nBạn có thể theo dõi trạng thái đơn hàng trong phần quản lý.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textGrey, fontSize: 16, height: 1.6),
                        ).animate().fadeIn(delay: 800.ms),
                        
                        const SizedBox(height: 48),

                        // Actions
                        Flex(
                          direction: isDesktop ? Axis.horizontal : Axis.vertical,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (isDesktop)
                                Expanded(child: _buildHomeButton(context))
                            else 
                                _buildHomeButton(context),
                                
                            if (isDesktop) const SizedBox(width: 16) else const SizedBox(height: 16),
                            
                            if (isDesktop)
                                Expanded(child: _buildDetailButton(context))
                            else
                                _buildDetailButton(context),
                          ],
                        ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2, end: 0),
                      ],
                    ),
                  ),
                ),
              ),
              ), // End SingleChildScrollView
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeButton(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: const Text('VỀ TRANG CHỦ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryGreen, letterSpacing: 0.5)),
    );
  }

  Widget _buildDetailButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        elevation: 4,
        shadowColor: AppTheme.primaryGreen.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: () {
        Navigator.of(context).pushAndRemoveUntil(
            OrderDetailPage.route(widget.orderId),
            (route) => route.isFirst
        );
      },
      child: const Text('XEM ĐƠN HÀNG VÀ\nTHANH TOÁN', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
    );
  }
}
