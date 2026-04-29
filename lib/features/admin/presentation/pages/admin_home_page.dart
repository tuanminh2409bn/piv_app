import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/common/widgets/responsive_wrapper.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/core/theme/nature_background_painter.dart';
import 'package:piv_app/core/utils/responsive.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_debt_management_page.dart';
import 'package:piv_app/features/admin/presentation/pages/quick_order_agent_selection_page.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_orders_page.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_products_page.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_categories_page.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_users_page.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_commissions_page.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_vouchers_page.dart';
import 'package:piv_app/features/admin/presentation/pages/manual_notification_page.dart';
import 'package:piv_app/features/admin/presentation/pages/notification_history_page.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_news_list_page.dart';
import 'package:piv_app/features/sales_commitment/presentation/pages/admin_commitments_page.dart';
import 'package:piv_app/features/lucky_wheel/presentation/pages/lucky_wheel_admin_page.dart';
import 'package:piv_app/features/notifications/presentation/widgets/notification_icon_with_badge.dart';
import 'package:piv_app/features/returns/presentation/pages/admin_return_requests_page.dart';
import 'package:piv_app/features/admin/presentation/pages/discount_settings_page.dart';
import 'package:piv_app/features/admin/presentation/pages/price_approval_page.dart';
import 'package:piv_app/features/admin/presentation/pages/return_policy_config_page.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_discount_requests_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final int crossAxisCount = Responsive.value(
      context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'BẢNG ĐIỀU KHIỂN ADMIN',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: false,
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: AppTheme.primaryGreen.withOpacity(0.3),
        actions: [
          const NotificationIconWithBadge(iconColor: Colors.white),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              tooltip: 'Đăng xuất tài khoản',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xác nhận đăng xuất'),
                    content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi hệ thống quản trị không?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.read<AuthBloc>().add(AuthLogoutRequested());
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed, foregroundColor: Colors.white),
                        child: const Text('Đăng xuất'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: NatureBackgroundPainter(
                color1: AppTheme.primaryGreen.withValues(alpha: 0.05),
                color2: AppTheme.secondaryGreen.withValues(alpha: 0.03),
                accent: AppTheme.accentGold.withValues(alpha: 0.1),
              ),
            ),
          ),
          ResponsiveWrapper(
            maxWidth: 1200,
            child: GridView.count(
              padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 24.0 + MediaQuery.of(context).padding.bottom),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: <Widget>[
                _DashboardCard(
                  title: 'Đơn hàng',
                  icon: Icons.shopping_cart_outlined,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminOrdersPage())),
                ),
                _DashboardCard(
                  title: 'Quản lý Công nợ',
                  icon: Icons.receipt_long_outlined,
                  onTap: () => Navigator.of(context).push(AdminDebtManagementPage.route()),
                ),
                _DashboardCard(
                  title: 'Duyệt Giá Riêng',
                  icon: Icons.approval,
                  onTap: () => Navigator.of(context).push(PriceApprovalPage.route()),
                ),
                _DashboardCard(
                  title: 'Duyệt Chiết Khấu',
                  icon: Icons.assignment_turned_in_outlined,
                  onTap: () => Navigator.of(context).push(AdminDiscountRequestsPage.route()),
                ),
                _DashboardCard(
                  title: 'Cấu hình Chiết khấu',
                  icon: Icons.price_change_outlined,
                  onTap: () => Navigator.of(context).push(DiscountSettingsPage.route()),
                ),
                _DashboardCard(
                  title: 'Quản lý Đổi/Trả',
                  icon: Icons.sync_problem_outlined,
                  onTap: () => Navigator.of(context).push(AdminReturnRequestsPage.route()),
                ),
                _DashboardCard(
                  title: 'Cấu hình Đổi Trả',
                  icon: Icons.settings_backup_restore_outlined,
                  onTap: () => Navigator.of(context).push(ReturnPolicyConfigPage.route()),
                ),
                _DashboardCard(
                  title: 'Sản phẩm',
                  icon: Icons.inventory_2_outlined,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminProductsPage())),
                ),
                _DashboardCard(
                  title: 'Danh mục',
                  icon: Icons.category_outlined,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminCategoriesPage())),
                ),
                _DashboardCard(
                  title: 'Người dùng',
                  icon: Icons.people_outline,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminUsersPage())),
                ),
                _DashboardCard(
                  title: 'Cài đặt Đặt nhanh',
                  icon: Icons.playlist_add_check_rounded,
                  onTap: () => Navigator.of(context).push(QuickOrderAgentSelectionPage.route()),
                ),
                _DashboardCard(
                  title: 'Soạn Thông Báo',
                  icon: Icons.send_rounded,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManualNotificationPage())),
                ),
                _DashboardCard(
                  title: 'Lịch Sử Gửi',
                  icon: Icons.history_rounded,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationHistoryPage())),
                ),
                _DashboardCard(
                  title: 'Quản lý Cam kết',
                  icon: Icons.workspace_premium_outlined,
                  onTap: () => Navigator.of(context).push(AdminCommitmentsPage.route()),
                ),
                _DashboardCard(
                  title: 'Vòng Quay May Mắn',
                  icon: Icons.casino_outlined,
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LuckyWheelAdminPage())
                  ),
                ),
                _DashboardCard(
                  title: 'Hoa hồng',
                  icon: Icons.percent_rounded,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminCommissionsPage())),
                ),
                _DashboardCard(
                  title: 'Vouchers',
                  icon: Icons.airplane_ticket_outlined,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminVouchersPage())),
                ),
                _DashboardCard(
                  title: 'Quản lý Tin tức',
                  icon: Icons.article_outlined,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminNewsListPage())),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  // ... (Widget này giữ nguyên không đổi)
  const _DashboardCard({
    required this.title,
    required this.icon,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  icon,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}