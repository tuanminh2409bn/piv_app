// lib/features/main/presentation/pages/main_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/auth/presentation/pages/login_page.dart';
import 'package:piv_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:piv_app/features/home/presentation/pages/home_page.dart';
import 'package:piv_app/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:piv_app/features/profile/presentation/pages/profile_page.dart';
import 'package:piv_app/features/products/presentation/pages/all_categories_page.dart';
import 'package:piv_app/features/profile/presentation/pages/qr_scanner_page.dart';
import 'package:piv_app/features/quick_order/presentation/pages/quick_order_page.dart';
import 'package:piv_app/features/main/presentation/widgets/glass_bottom_navigation.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/features/sales_commitment/presentation/bloc/agent/sales_commitment_agent_cubit.dart';
import 'package:piv_app/data/models/sales_commitment_model.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final HomeCubit _homeCubit = sl<HomeCubit>();
  final ProfileCubit _profileCubit = sl<ProfileCubit>();
  final SalesCommitmentAgentCubit _salesCommitmentAgentCubit = sl<SalesCommitmentAgentCubit>();

  bool _isCommitmentDialogShowing = false;

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
  void dispose() {
    _salesCommitmentAgentCubit.close();
    super.dispose();
  }

  void _onItemTapped(int index) {
    // Kiểm tra đăng nhập khi vào các tab nhạy cảm
    if (index == 3) {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        Navigator.of(context).push(LoginPage.route());
        return;
      }
    }
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
        BlocProvider.value(value: _salesCommitmentAgentCubit),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthAuthenticated) {
                _profileCubit.fetchUserProfile(state.user.id);
              } else if (state is AuthUnauthenticated) {
                // Khi đăng xuất, quay về trang chủ để tránh kẹt ở tab Tài khoản/Đặt nhanh
                setState(() {
                  _selectedIndex = 0;
                });
              }
            },
          ),
          BlocListener<ProfileCubit, ProfileState>(
            listener: (context, state) {
              if (state.status == ProfileStatus.success && state.user.referralPromptPending) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _showReferralPromptDialog(context);
                  }
                });
              }
            },
          ),
          BlocListener<SalesCommitmentAgentCubit, SalesCommitmentAgentState>(
            listener: (context, state) {
              // Chỉ trigger khi status == success (bỏ qua loading để tránh re-trigger)
              if (state.status == SalesCommitmentAgentStatus.success &&
                  state.activeCommitment != null &&
                  state.activeCommitment!.status == 'proposed_to_agent' &&
                  !_isCommitmentDialogShowing) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _showCommitmentProposalDialog(context, state.activeCommitment!);
                  }
                });
              }
            },
          ),
        ],
        child: Scaffold(
          extendBody: true, // Quan trọng: Cho phép nội dung tràn xuống dưới BottomBar
          body: IndexedStack(
            index: _selectedIndex,
            children: _widgetOptions,
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
    ),
  );
}

  void _showReferralPromptDialog(BuildContext context) {
    final profileCubit = context.read<ProfileCubit>();
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
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
                        final scannedCode = await Navigator.of(dialogContext).push<String?>(QrScannerPage.route());
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
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('XÁC NHẬN'),
              onPressed: () {
                if (codeController.text.trim().isNotEmpty) {
                  profileCubit.submitReferralCode(codeController.text.trim());
                  Navigator.of(dialogContext).pop();
                } else {
                  profileCubit.dismissReferralPrompt();
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCommitmentProposalDialog(BuildContext context, SalesCommitmentModel commitment) {
    if (_isCommitmentDialogShowing) return;
    _isCommitmentDialogShowing = true;

    final currencyFormatter = NumberFormat.decimalPattern('vi_VN');
    final dateFormatter = DateFormat('dd/MM/yyyy');

    showDialog(
      context: context,
      barrierDismissible: false, // Bắt buộc đồng ý hoặc từ chối
      builder: (dialogContext) {
        return BlocProvider.value(
          value: _salesCommitmentAgentCubit,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.mark_email_unread_outlined, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                const Text(
                  'Đề xuất Cam kết mới',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bạn nhận được đề xuất cam kết từ ${commitment.commitmentDetails?.setByUserName ?? 'Công ty'}:',
                    style: const TextStyle(fontSize: 14, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Mức cam kết:', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${currencyFormatter.format(commitment.targetAmount)} VNĐ',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Thời gian:', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${dateFormatter.format(commitment.startDate)} - ${dateFormatter.format(commitment.endDate)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chi tiết quyền lợi & phần thưởng:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textGrey),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      commitment.commitmentDetails?.text ?? 'Không có chi tiết.',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textDark, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Pop trước để flag vẫn còn true trong lúc loading state được xử lý
                  Navigator.of(dialogContext).pop();
                  _salesCommitmentAgentCubit.respondToCommitmentProposal(
                    commitmentId: commitment.id,
                    isAccepted: false,
                  );
                },
                child: const Text('TỪ CHỐI', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () {
                  // Pop trước để flag vẫn còn true trong lúc loading state được xử lý
                  Navigator.of(dialogContext).pop();
                  _salesCommitmentAgentCubit.respondToCommitmentProposal(
                    commitmentId: commitment.id,
                    isAccepted: true,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('ĐỒNG Ý', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    // Reset flag CHỈ khi dialog đã đóng hoàn toàn (sau animation pop)
    ).then((_) {
      if (mounted) {
        setState(() {
          _isCommitmentDialogShowing = false;
        });
      }
    });
  }
}