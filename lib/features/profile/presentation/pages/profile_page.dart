// lib/features/profile/presentation/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/core/theme/nature_background_painter.dart'; // Import Painter
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/data/models/address_model.dart';
import 'package:piv_app/features/orders/presentation/pages/my_orders_page.dart';
import 'package:piv_app/features/wishlist/presentation/pages/wishlist_page.dart';
import 'package:piv_app/features/profile/presentation/pages/qr_scanner_page.dart';
import 'package:piv_app/features/sales_commitment/presentation/pages/sales_commitment_page.dart';
import 'package:piv_app/features/lucky_wheel/presentation/pages/lucky_wheel_page.dart';
import 'package:piv_app/features/profile/presentation/pages/debt_payment_page.dart';
import 'package:url_launcher/url_launcher.dart';

// --- HELPER FUNCTION ---
Future<void> _launchURL(BuildContext context, String urlString) async {
  final Uri url = Uri.parse(urlString);
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể mở đường dẫn: $urlString')),
      );
    }
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<ProfileCubit>(),
      child: const ProfileView(),
    );
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state.status == ProfileStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
        }
      },
      builder: (context, state) {
        if (state.status == ProfileStatus.loading || state.status == ProfileStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.user.isEmpty && state.status != ProfileStatus.loading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Không thể tải thông tin người dùng.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                     context.read<AuthBloc>().add(AuthLogoutRequested());
                  },
                  child: const Text('Đăng xuất & Thử lại'),
                )
              ],
            ),
          );
        }

        final user = state.user;
        final bool isAgent = user.role == 'agent_1' || user.role == 'agent_2';

        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          body: RefreshIndicator(
            onRefresh: () async {
              final userId = context.read<ProfileCubit>().state.user.id;
              if (userId.isNotEmpty) {
                context.read<ProfileCubit>().fetchUserProfile(userId);
              }
            },
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(context, user),
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (isAgent) ...[
                           _buildFinancialSection(context, user),
                           const SizedBox(height: 24),
                        ],
                        
                        _buildSectionTitle(context, 'Quản lý'),
                        _buildManagementOptions(context, user),
                        const SizedBox(height: 24),

                        _buildSectionTitle(context, 'Cá nhân'),
                        _ProfileForm(user: user),
                        const SizedBox(height: 16),
                        _AddressSection(addresses: user.addresses),
                        const SizedBox(height: 24),

                        _buildSectionTitle(context, 'Hỗ trợ'),
                        _buildLegalAndSupportSection(context),
                        
                        if (isAgent) ...[
                          const SizedBox(height: 24),
                          _buildSectionTitle(context, 'Vùng nguy hiểm'),
                          _buildDeleteAccountSection(context, state.status),
                        ],

                        const SizedBox(height: 32),
                        
                        // --- LOGOUT BUTTON ---
                        _buildLogoutButton(context),
                        
                        const SizedBox(height: 40),
                        Center(
                          child: Text(
                            'Phiên bản 1.0.2', 
                            style: TextStyle(color: Colors.grey.withValues(alpha: 0.5), fontSize: 12)
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, UserModel user) {
    return SliverAppBar(
      expandedHeight: 180.0,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryGreen,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Nền Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryGreen,
                    AppTheme.secondaryGreen,
                  ],
                ),
              ),
            ),
            // Họa tiết phủ lên
            Positioned.fill(
              child: CustomPaint(
                painter: NatureBackgroundPainter(
                  color1: Colors.white.withValues(alpha: 0.1),
                  color2: Colors.white.withValues(alpha: 0.05),
                  accent: AppTheme.accentGold.withValues(alpha: 0.2),
                ),
              ),
            ),
            // Nội dung chính
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: Text(
                        user.displayName?.isNotEmpty == true ? user.displayName![0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 32, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.displayName ?? 'Người dùng',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user.email ?? '',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: AppTheme.textGrey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          _showLogoutConfirmationDialog(context);
        },
        icon: const Icon(Icons.logout),
        label: const Text('ĐĂNG XUẤT'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.errorRed,
          side: const BorderSide(color: AppTheme.errorRed),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Đăng xuất?'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: <Widget>[
            TextButton(
              child: const Text('HỦY', style: TextStyle(color: AppTheme.textGrey)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('ĐĂNG XUẤT'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<AuthBloc>().add(AuthLogoutRequested());
              },
            ),
          ],
        );
      },
    );
  }

  // --- FINANCIAL SECTION ---
  Widget _buildFinancialSection(BuildContext context, UserModel user) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final debtAmount = user.debtAmount;
    final hasDebt = debtAmount > 0;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Công nợ hiện tại', style: TextStyle(color: AppTheme.textGrey)),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(debtAmount),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: hasDebt ? AppTheme.errorRed : AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (hasDebt ? AppTheme.errorRed : AppTheme.primaryGreen).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: hasDebt ? AppTheme.errorRed : AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Thanh toán Công nợ', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textGrey),
            onTap: () => Navigator.of(context).push(DebtPaymentPage.route()),
          ),
        ],
      ),
    );
  }

  // --- MANAGEMENT OPTIONS ---
  Widget _buildManagementOptions(BuildContext context, UserModel user) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: Column(
        children: [
          _buildListTile(context, Icons.receipt_long_outlined, 'Đơn hàng của tôi', () => Navigator.of(context).push(MyOrdersPage.route()), Colors.blue),
          _buildDivider(),
          _buildListTile(context, Icons.favorite_border_outlined, 'Danh sách yêu thích', () => Navigator.of(context).push(WishlistPage.route()), Colors.red),
          
          if (user.role == 'agent_1' || user.role == 'agent_2') ...[
            _buildDivider(),
            _buildListTile(context, Icons.military_tech_outlined, 'Chương trình thưởng', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SalesCommitmentPage())), Colors.amber),
            _buildDivider(),
            _buildListTile(context, Icons.casino_outlined, 'Vòng Quay May Mắn', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LuckyWheelPage())), Colors.purple),
          ],

          if (!user.isAdmin && !user.isSalesRep) ...[
             _buildDivider(),
             if (user.salesRepId != null && user.salesRepId!.isNotEmpty)
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.support_agent_outlined, color: Colors.green)),
                  title: const Text('NVKD phụ trách', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(user.salesRepId ?? '', style: const TextStyle(fontSize: 12)),
                )
             else
                _buildListTile(context, Icons.card_giftcard_outlined, 'Nhập mã giới thiệu', () => _showReferralInputDialog(context), Colors.orange),
          ]
        ],
      ),
    );
  }

  Widget _buildListTile(BuildContext context, IconData icon, String title, VoidCallback onTap, Color iconColor) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textGrey),
      onTap: onTap,
    );
  }

  Widget _buildDivider() => Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1), indent: 16, endIndent: 16);

  void _showReferralInputDialog(BuildContext context) {
    // ... Giữ nguyên logic cũ ...
    final profileCubit = context.read<ProfileCubit>();
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: profileCubit,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Nhập mã giới thiệu'),
          content: Form(
            key: formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: codeController,
                    decoration: const InputDecoration(labelText: 'Mã giới thiệu', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập mã' : null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () async {
                    final scannedCode = await Navigator.of(context).push<String?>(QrScannerPage.route());
                    if (scannedCode != null && scannedCode.isNotEmpty) {
                      codeController.text = scannedCode;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(child: const Text('HỦY'), onPressed: () => Navigator.of(context).pop()),
            ElevatedButton(
              child: const Text('XÁC NHẬN'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  profileCubit.submitReferralCode(codeController.text.trim());
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- LEGAL & SUPPORT ---
  Widget _buildLegalAndSupportSection(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: Column(
        children: [
          _buildListTile(context, Icons.description_outlined, 'Điều khoản Dịch vụ', () => _launchURL(context, 'https://tuanminh2409bn.github.io/piv-terms/'), Colors.blueGrey),
          _buildDivider(),
          _buildListTile(context, Icons.privacy_tip_outlined, 'Chính sách Bảo mật', () => _launchURL(context, 'https://tuanminh2409bn.github.io/piv-privacy/'), Colors.blueGrey),
        ],
      ),
    );
  }

  // --- DELETE ACCOUNT ---
  Widget _buildDeleteAccountSection(BuildContext context, ProfileStatus status) {
    return Card(
      color: Colors.red.withValues(alpha: 0.05),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed),
                const SizedBox(width: 8),
                const Text('Xóa tài khoản vĩnh viễn', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Hành động này sẽ xóa toàn bộ dữ liệu của bạn và không thể hoàn tác.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            if (status == ProfileStatus.updating)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorRed,
                    side: const BorderSide(color: AppTheme.errorRed),
                  ),
                  onPressed: () => _showDeleteConfirmationDialog(context),
                  child: const Text('YÊU CẦU XÓA TÀI KHOẢN'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    // ... Giữ nguyên logic cũ ...
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cảnh báo!'),
          content: const Text('Hành động này không thể hoàn tác. Bạn có chắc chắn muốn xóa tài khoản?'),
          actions: <Widget>[
            TextButton(child: const Text('HỦY BỎ'), onPressed: () => Navigator.of(dialogContext).pop()),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
              child: const Text('XÓA TÀI KHOẢN'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<ProfileCubit>().deleteAccount();
              },
            ),
          ],
        );
      },
    );
  }
}

// --- PROFILE FORM & ADDRESS (Refactored to match Theme) ---

class _ProfileForm extends StatefulWidget {
  final UserModel user;
  const _ProfileForm({required this.user});
  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  // ... (Logic giữ nguyên, chỉ thay đổi UI một chút) ...
  late final TextEditingController _displayNameController;
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.user.displayName);
  }
  @override
  void dispose() { _displayNameController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Thông tin cơ bản', style: TextStyle(fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () => setState(() => _isEditing = !_isEditing),
                    child: Text(
                      _isEditing ? 'Hủy' : 'Sửa',
                      style: TextStyle(color: _isEditing ? AppTheme.errorRed : AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _displayNameController,
                enabled: _isEditing,
                decoration: const InputDecoration(labelText: 'Tên hiển thị', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => _isEditing && (v == null || v.trim().isEmpty) ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: widget.user.email,
                enabled: false,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined), filled: true),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: BlocBuilder<ProfileCubit, ProfileState>(
                    builder: (context, state) {
                      return state.status == ProfileStatus.updating
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<ProfileCubit>().profileFieldChanged(displayName: _displayNameController.text.trim());
                                  context.read<ProfileCubit>().saveUserProfile();
                                  setState(() => _isEditing = false);
                                }
                              },
                              child: const Text('LƯU THAY ĐỔI'),
                            );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressSection extends StatelessWidget {
  final List<AddressModel> addresses;
  const _AddressSection({required this.addresses});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(context, 'Sổ địa chỉ'),
            TextButton.icon(
              onPressed: () => _showAddressFormDialog(context),
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text('Thêm mới'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        if (addresses.isEmpty)
          const Padding(padding: EdgeInsets.all(16.0), child: Text('Chưa có địa chỉ nào.', style: TextStyle(color: Colors.grey)))
        else
          ListView.separated(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _AddressCard(address: addresses[index]),
          ),
      ],
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(title.toUpperCase(), style: TextStyle(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2));
  }
}

class _AddressCard extends StatelessWidget {
  final AddressModel address;
  const _AddressCard({required this.address});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: address.isDefault ? AppTheme.primaryGreen : Colors.grey.withValues(alpha: 0.2), width: address.isDefault ? 1.5 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: AppTheme.textGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(address.recipientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: const Text('Mặc định', style: TextStyle(fontSize: 10, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: AppTheme.textGrey),
                  onSelected: (value) {
                    if (value == 'edit') _showAddressFormDialog(context, address: address);
                    if (value == 'delete') _confirmDelete(context);
                    if (value == 'default') context.read<ProfileCubit>().setDefaultAddress(address.id);
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    if (!address.isDefault)
                      const PopupMenuItem<String>(value: 'default', child: Text('Đặt làm mặc định')),
                    const PopupMenuItem<String>(value: 'edit', child: Text('Sửa')),
                    const PopupMenuItem<String>(value: 'delete', child: Text('Xóa', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 26.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(address.phoneNumber, style: const TextStyle(fontSize: 13, color: AppTheme.textGrey)),
                  const SizedBox(height: 4),
                  Text(address.street, style: const TextStyle(fontSize: 14)),
                  Text('${address.ward}, ${address.city}', style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa địa chỉ?'),
        content: const Text('Bạn có chắc chắn muốn xóa địa chỉ này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              context.read<ProfileCubit>().deleteAddress(address.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }
}

void _showAddressFormDialog(BuildContext context, {AddressModel? address}) {
  final profileCubit = context.read<ProfileCubit>();
  showDialog(
    context: context,
    builder: (_) => BlocProvider.value(
      value: profileCubit,
      child: _AddressFormDialog(address: address),
    ),
  );
}

// ... _AddressFormDialog giữ nguyên logic, chỉ cập nhật UI nhẹ (đã viết lại ở dưới cho đầy đủ) ...

class _AddressFormDialog extends StatefulWidget {
  final AddressModel? address;
  const _AddressFormDialog({this.address});
  @override
  State<_AddressFormDialog> createState() => _AddressFormDialogState();
}

class _AddressFormDialogState extends State<_AddressFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController, _phoneController, _streetController, _wardController, _cityController;
  late bool _isDefault;
  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.address?.recipientName ?? '');
    _phoneController = TextEditingController(text: widget.address?.phoneNumber ?? '');
    _streetController = TextEditingController(text: widget.address?.street ?? '');
    _wardController = TextEditingController(text: widget.address?.ward ?? '');
    _cityController = TextEditingController(text: widget.address?.city ?? '');
    _isDefault = widget.address?.isDefault ?? false;
  }
  @override
  void dispose() { _nameController.dispose(); _phoneController.dispose(); _streetController.dispose(); _wardController.dispose(); _cityController.dispose(); super.dispose(); }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final newAddress = AddressModel(
          id: widget.address?.id, recipientName: _nameController.text.trim(), phoneNumber: _phoneController.text.trim(),
          street: _streetController.text.trim(), ward: _wardController.text.trim(), city: _cityController.text.trim(), isDefault: _isDefault
      );
      if (_isEditing) context.read<ProfileCubit>().updateAddress(newAddress);
      else context.read<ProfileCubit>().addAddress(newAddress);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Sửa địa chỉ' : 'Thêm địa chỉ mới'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _tf(_nameController, 'Họ và tên'),
              _tf(_phoneController, 'Số điện thoại', type: TextInputType.phone),
              _tf(_streetController, 'Số nhà, tên đường'),
              _tf(_wardController, 'Phường/Xã'),
              _tf(_cityController, 'Tỉnh/Thành phố'),
              SwitchListTile(title: const Text('Đặt làm mặc định'), value: _isDefault, onChanged: (v) => setState(() => _isDefault = v), contentPadding: EdgeInsets.zero),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('HỦY')),
        ElevatedButton(onPressed: _onSave, child: const Text('LƯU')),
      ],
    );
  }
  Widget _tf(TextEditingController c, String l, {TextInputType? type}) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: TextFormField(controller: c, decoration: InputDecoration(labelText: l, border: const OutlineInputBorder()), keyboardType: type, validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null));
}