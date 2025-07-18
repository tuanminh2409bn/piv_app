import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_orders_page.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_products_page.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_categories_page.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_users_page.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_commissions_page.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_vouchers_page.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_settings_page.dart';
import 'package:piv_app/features/admin/presentation/pages/manual_notification_page.dart';
import 'package:piv_app/features/admin/presentation/pages/notification_history_page.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_news_list_page.dart';


class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều khiển Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: <Widget>[
            _DashboardCard(
              title: 'Đơn hàng',
              icon: Icons.shopping_cart_outlined,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminOrdersPage())),
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
            // SỬA: Đổi tên "Thông báo" thành "Soạn Thông Báo" cho rõ ràng
            _DashboardCard(
              title: 'Soạn Thông Báo',
              icon: Icons.send_rounded, // Đổi icon cho phù hợp
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManualNotificationPage())),
            ),
            // SỬA: Thêm thẻ chức năng "Lịch Sử Thông Báo"
            _DashboardCard(
              title: 'Lịch Sử Gửi',
              icon: Icons.history_rounded,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationHistoryPage())),
            ),
            _DashboardCard(
              title: 'Hoa hồng',
              icon: Icons.percent_rounded,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminCommissionsPage())),
            ),
            _DashboardCard(
              title: 'Vouchers', // Đổi tên cho ngắn gọn
              icon: Icons.airplane_ticket_outlined,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminVouchersPage())),
            ),
            _DashboardCard(
              title: 'Cài đặt',
              icon: Icons.settings_outlined,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminSettingsPage())),
            ),
            _DashboardCard(
              title: 'Quản lý Tin tức',
              icon: Icons.article_outlined,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminNewsListPage())),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
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