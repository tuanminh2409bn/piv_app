// lib/features/main/presentation/pages/main_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/cart/presentation/pages/cart_page.dart';
import 'package:piv_app/features/cart/presentation/widgets/cart_icon_with_badge.dart';
import 'package:piv_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:piv_app/features/home/presentation/pages/home_page.dart';
import 'package:piv_app/features/notifications/presentation/widgets/notification_icon_with_badge.dart';
import 'package:piv_app/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:piv_app/features/profile/presentation/pages/profile_page.dart';
import 'package:piv_app/features/products/presentation/pages/all_categories_page.dart';
import 'package:piv_app/features/profile/presentation/pages/qr_scanner_page.dart';
import 'package:piv_app/features/quick_order/presentation/pages/quick_order_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final HomeCubit _homeCubit = sl<HomeCubit>();
  final ProfileCubit _profileCubit = sl<ProfileCubit>();

  late final List<Widget> _widgetOptions;

  // <<< SỬA ĐỔI 1: Thêm tiêu đề cho trang "Đặt hàng nhanh" >>>
  static const List<String> _appBarTitles = <String>[
    'Phân Bón PIV',
    'Tất cả Danh mục',
    'Đặt hàng nhanh', // Tiêu đề mới
    'Tài khoản'
  ];

  @override
  void initState() {
    super.initState();
    // <<< SỬA ĐỔI 2: Thêm trang QuickOrderPage vào danh sách màn hình >>>
    _widgetOptions = <Widget>[
      const HomePage(),
      const AllCategoriesPage(),
      const QuickOrderPage(), // Màn hình mới
      BlocProvider.value(
        value: _profileCubit,
        child: const ProfilePage(),
      ),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<AuthBloc>().stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        _profileCubit.fetchUserProfile(authState.user.id);
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _homeCubit),
        BlocProvider.value(value: _profileCubit),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _appBarTitles[_selectedIndex],
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: false,
          automaticallyImplyLeading: false,
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
            // <<< SỬA ĐỔI 3: Xóa IconButton Đặt hàng nhanh khỏi đây >>>
            /*
            IconButton(
              icon: const Icon(Icons.flash_on_outlined),
              tooltip: 'Đặt hàng nhanh',
              onPressed: () {
                Navigator.of(context).push(QuickOrderPage.route());
              },
            ),
            */
            const NotificationIconWithBadge(iconColor: Colors.white),
            CartIconWithBadge(
              iconColor: Colors.white,
              onPressed: () {
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
            const SizedBox(width: 4),
          ],
        ),
        body: BlocListener<ProfileCubit, ProfileState>(
          listener: (context, state) {
            if (state.status == ProfileStatus.success && state.user.referralPromptPending) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _showReferralPromptDialog(context);
                }
              });
            }
          },
          child: Center(
            child: _widgetOptions.elementAt(_selectedIndex),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          // <<< SỬA ĐỔI 4: Thêm mục "Đặt nhanh" vào đây >>>
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Trang chủ'),
            BottomNavigationBarItem(icon: Icon(Icons.category_outlined), activeIcon: Icon(Icons.category), label: 'Danh mục'),
            BottomNavigationBarItem(icon: Icon(Icons.shop_2_outlined), activeIcon: Icon(Icons.shop_2), label: 'Đặt nhanh'),
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

  void _showReferralPromptDialog(BuildContext context) {
    // ... Giữ nguyên hàm này ...
    final profileCubit = context.read<ProfileCubit>();
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: profileCubit,
        child: AlertDialog(
          title: const Text('Chào mừng bạn!'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Nếu bạn có mã giới thiệu từ nhân viên kinh doanh, vui lòng nhập vào bên dưới.'),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: codeController,
                        decoration: const InputDecoration(labelText: 'Nhập mã tại đây'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      tooltip: 'Quét mã QR',
                      onPressed: () async {
                        final scannedCode = await Navigator.of(context).push<String?>(QrScannerPage.route());
                        if (scannedCode != null && scannedCode.isNotEmpty) {
                          codeController.text = scannedCode;
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('BỎ QUA'),
              onPressed: () {
                profileCubit.dismissReferralPrompt();
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('XÁC NHẬN'),
              onPressed: () {
                if (codeController.text.trim().isNotEmpty) {
                  profileCubit.submitReferralCode(codeController.text.trim());
                  Navigator.of(context).pop();
                } else {
                  profileCubit.dismissReferralPrompt();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}