// lib/features/main/presentation/pages/main_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/core/theme/app_theme.dart';
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
import 'package:piv_app/features/main/presentation/widgets/glass_bottom_navigation.dart';

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

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const HomePage(),
      const AllCategoriesPage(),
      const QuickOrderPage(),
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
        extendBody: true, // Quan trọng: Cho phép nội dung tràn xuống dưới BottomBar
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
          child: IndexedStack(
            index: _selectedIndex,
            children: _widgetOptions,
          ),
        ),
        bottomNavigationBar: GlassBottomNavigation(
          currentIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
          items: [
            GlassNavigationItem(
              icon: Icons.home_outlined, 
              activeIcon: Icons.home, 
              label: 'Trang chủ'
            ),
            GlassNavigationItem(
              icon: Icons.category_outlined, 
              activeIcon: Icons.category, 
              label: 'Danh mục'
            ),
            GlassNavigationItem(
              icon: Icons.shopping_bag_outlined, 
              activeIcon: Icons.shopping_bag, 
              label: 'Đặt nhanh'
            ),
            GlassNavigationItem(
              icon: Icons.person_outline, 
              activeIcon: Icons.person, 
              label: 'Tài khoản'
            ),
          ],
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