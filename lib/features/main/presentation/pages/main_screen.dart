import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/cart/presentation/pages/cart_page.dart';
import 'package:piv_app/features/cart/presentation/widgets/cart_icon_with_badge.dart';
import 'package:piv_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:piv_app/features/home/presentation/pages/home_page.dart';
import 'package:piv_app/features/profile/presentation/pages/profile_page.dart';
import 'package:piv_app/features/products/presentation/pages/all_categories_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // ** QUAN TRỌNG: Cung cấp HomeCubit ở đây **
  // để tất cả các trang con (HomePage, AllCategoriesPage) có thể sử dụng chung.
  // Chúng ta chỉ cần tạo 1 instance và tải dữ liệu 1 lần.
  final HomeCubit _homeCubit = sl<HomeCubit>()..fetchHomeScreenData();

  // Danh sách các trang chính tương ứng với các tab
  // Các trang này sẽ không còn Scaffold hay AppBar riêng nữa.
  static final List<Widget> _widgetOptions = <Widget>[
    const HomePage(),
    const AllCategoriesPage(),
    const ProfilePage(),
  ];

  // Danh sách các tiêu đề tương ứng với mỗi tab
  static const List<String> _appBarTitles = <String>[
    'Phân Bón PIV',
    'Tất cả Danh mục',
    'Tài khoản',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng BlocProvider.value để cung cấp instance _homeCubit đã tạo
    // cho tất cả các widget con trong MainScreen.
    return BlocProvider.value(
      value: _homeCubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _appBarTitles[_selectedIndex],
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          // Căn lề trái cho tiêu đề
          centerTitle: false,
          automaticallyImplyLeading: false, // Ẩn nút back
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade800, Colors.green.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          actionsIconTheme: const IconThemeData(color: Colors.white),
          actions: [
            // Nút Giỏ hàng sẽ luôn hiển thị trên AppBar
            CartIconWithBadge(
              iconColor: Colors.white,
              onPressed: () {
                // Khi nhấn vào, chúng ta sẽ push một trang Giỏ hàng mới
                // Trang này sẽ có nút back để quay lại.
                Navigator.of(context).push(CartPage.route());
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Đăng xuất',
              onPressed: () {
                context.read<AuthBloc>().add(AuthLogoutRequested());
              },
            ),
          ],
        ),
        body: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Trang chủ'),
            BottomNavigationBarItem(icon: Icon(Icons.category_outlined), activeIcon: Icon(Icons.category), label: 'Danh mục'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Tài khoản'),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey.shade600,
          showUnselectedLabels: true,
        ),
      ),
    );
  }
}
