import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_orders_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const AdminHomePage());
  }

  @override
  Widget build(BuildContext context) {
    // Không cần MultiBlocProvider ở đây nữa, vì mỗi trang con sẽ tự quản lý Cubit của mình
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều khiển'),
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
        // Sử dụng GridView để tạo bố cục lưới
        child: GridView.count(
          crossAxisCount: 2, // Hiển thị 2 cột
          crossAxisSpacing: 12, // Khoảng cách ngang giữa các thẻ
          mainAxisSpacing: 12,  // Khoảng cách dọc giữa các thẻ
          children: <Widget>[
            // --- DANH SÁCH CÁC THẺ CHỨC NĂNG ---
            _DashboardCard(
              title: 'Đơn hàng',
              subtitle: 'Quản lý các đơn hàng', // Tùy chọn: Thêm mô tả ngắn
              icon: Icons.shopping_cart_outlined,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AdminOrdersPage(),
                ));
              },
            ),
            _DashboardCard(
              title: 'Sản phẩm',
              icon: Icons.inventory_2_outlined,
              onTap: () {
                // TODO: Bước 3 - Điều hướng đến trang quản lý sản phẩm
              },
            ),
            _DashboardCard(
              title: 'Danh mục',
              icon: Icons.category_outlined,
              onTap: () {
                // TODO: Bước 3 - Điều hướng đến trang quản lý danh mục
              },
            ),
            _DashboardCard(
              title: 'Người dùng',
              icon: Icons.people_outline,
              onTap: () {
                // TODO: Bước 3 - Điều hướng đến trang quản lý người dùng
              },
            ),
            _DashboardCard(
              title: 'Hoa hồng',
              icon: Icons.percent_rounded,
              onTap: () {
                // TODO: Bước 3 - Điều hướng đến trang quản lý hoa hồng
              },
            ),
            _DashboardCard(
              title: 'Duyệt Voucher',
              icon: Icons.airplane_ticket_outlined,
              onTap: () {
                // TODO: Bước 3 - Điều hướng đến trang duyệt voucher
              },
            ),
            _DashboardCard(
              title: 'Cài đặt',
              icon: Icons.settings_outlined,
              onTap: () {
                // TODO: Bước 3 - Điều hướng đến trang cài đặt
              },
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
//        WIDGET THẺ CHỨC NĂNG (ĐÃ THIẾT KẾ Ở BƯỚC 1)
// =================================================================
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