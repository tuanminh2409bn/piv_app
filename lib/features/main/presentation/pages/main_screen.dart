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
        // The AppBar is now removed from here. Each page in _widgetOptions will have its own.
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
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              )
            ],
            border: Border(
              top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
            ),
          ),
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Trang chủ'),
              BottomNavigationBarItem(icon: Icon(Icons.category_outlined), activeIcon: Icon(Icons.category), label: 'Danh mục'),
              BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag), label: 'Đặt nhanh'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Tài khoản'),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent, // Use container's color
            elevation: 0, // Use container's shadow
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: AppTheme.textGrey,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            showUnselectedLabels: true,
          ),
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