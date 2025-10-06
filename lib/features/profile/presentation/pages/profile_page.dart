// lib/features/profile/presentation/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // <--- THÊM IMPORT NÀY
import 'package:piv_app/core/di/injection_container.dart';
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

// --- PHẦN NÀY KHÔNG THAY ĐỔI ---
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
              backgroundColor: Theme.of(context).colorScheme.error,
            ));
        }
      },
      builder: (context, state) {
        if (state.status == ProfileStatus.loading || state.status == ProfileStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.user.isEmpty && state.status != ProfileStatus.loading) {
          return const Center(child: Text('Không thể tải thông tin người dùng.'));
        }

        final user = state.user;
        final bool isAgent = user.role == 'agent_1' || user.role == 'agent_2';

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              final userId = context.read<ProfileCubit>().state.user.id;
              if (userId.isNotEmpty) {
                context.read<ProfileCubit>().fetchUserProfile(userId);
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // --- BẮT ĐẦU THAY ĐỔI ---
                  if (isAgent) ...[
                    _buildFinancialSection(context, user),
                    const Divider(thickness: 8, height: 24, color: Color(0xFFF2F2F7)),
                  ],
                  _buildManagementOptions(context, user),
                  // --- KẾT THÚC THAY ĐỔI ---
                  const Divider(thickness: 8, height: 24, color: Color(0xFFF2F2F7)),
                  _buildReferralSection(context, user),
                  const Divider(thickness: 8, height: 24, color: Color(0xFFF2F2F7)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _ProfileForm(user: user),
                  ),
                  const SizedBox(height: 24),
                  const Divider(thickness: 8, height: 24, color: Color(0xFFF2F2F7)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                    child: _AddressSection(addresses: user.addresses),
                  ),
                  if (isAgent) ...[
                    const Divider(thickness: 8, height: 24, color: Color(0xFFF2F2F7)),
                    _buildDeleteAccountSection(context, state.status),
                  ],
                  const Divider(thickness: 8, height: 24, color: Color(0xFFF2F2F7)),
                  _buildLegalAndSupportSection(context),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- BẮT ĐẦU WIDGET MỚI ---
  Widget _buildFinancialSection(BuildContext context, UserModel user) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final debtAmount = user.debtAmount;
    final hasDebt = debtAmount > 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thông tin tài chính',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Công nợ hiện tại', style: TextStyle(fontSize: 16)),
                      // SỬA LỖI TRÀN: Bọc Text bằng Expanded
                      Expanded(
                        child: Text(
                          currencyFormat.format(debtAmount),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: hasDebt ? Colors.red.shade700 : Colors.green.shade800,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, thickness: 0.5),
        ListTile(
          leading: Icon(Icons.payment_outlined, color: Colors.purple.shade400),
          title: const Text('Thanh toán Công nợ'),
          subtitle: const Text('Thanh toán toàn bộ hoặc một phần công nợ'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // SỬA LỖI: Xóa SnackBar không cần thiết
            Navigator.of(context).push(DebtPaymentPage.route());
          },
        ),
      ],
    );
  }


  // --- CÁC HÀM BUILD KHÁC KHÔNG THAY ĐỔI ---
  Widget _buildLegalAndSupportSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin & Hỗ trợ',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Điều khoản Dịch vụ'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchURL(context, 'https://tuanminh2409bn.github.io/piv-terms/'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Chính sách Bảo mật'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchURL(context, 'https://tuanminh2409bn.github.io/piv-privacy/'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountSection(BuildContext context, ProfileStatus status) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quản lý tài khoản',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (status == ProfileStatus.updating)
            const Center(child: CircularProgressIndicator())
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Yêu cầu xóa tài khoản'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: () => _showDeleteConfirmationDialog(context),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Lưu ý: Hành động này sẽ xóa vĩnh viễn tài khoản và toàn bộ dữ liệu liên quan theo chính sách của PIV và App Store.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Bạn có chắc chắn?'),
          content: const Text(
            'Hành động này không thể hoàn tác. Toàn bộ dữ liệu của bạn, bao gồm lịch sử đơn hàng, sẽ bị xóa vĩnh viễn. \n\nBạn có chắc chắn muốn tiếp tục?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('HỦY BỎ'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

  Widget _buildManagementOptions(BuildContext context, UserModel user) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.receipt_long_outlined, color: Colors.lightBlueAccent),
          title: const Text('Đơn hàng của tôi'),
          subtitle: const Text('Xem lịch sử các đơn hàng đã đặt'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.of(context).push(MyOrdersPage.route());
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        ListTile(
          leading: const Icon(Icons.favorite_border_outlined, color: Colors.redAccent),
          title: const Text('Danh sách yêu thích'),
          subtitle: const Text('Xem lại các sản phẩm đã lưu'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.of(context).push(WishlistPage.route());
          },
        ),
        if (user.role == 'agent_1' || user.role == 'agent_2') ...[
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.military_tech_outlined, color: Colors.amber),
            title: const Text('Chương trình thưởng'),
            subtitle: const Text('Đăng ký & theo dõi cam kết'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SalesCommitmentPage()),
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.casino_outlined, color: Colors.teal),
            title: const Text('Vòng Quay May Mắn'),
            subtitle: const Text('Nhận quà liền tay, vận may mỗi ngày'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LuckyWheelPage()),
              );
            },
          ),
        ]
      ],
    );
  }

  Widget _buildReferralSection(BuildContext context, UserModel user) {
    if (user.isAdmin || user.isSalesRep) {
      return const SizedBox.shrink();
    }

    if (user.salesRepId != null && user.salesRepId!.isNotEmpty) {
      return ListTile(
        leading: const Icon(Icons.support_agent_outlined, color: Colors.green),
        title: const Text('Nhân viên kinh doanh phụ trách'),
        subtitle: Text('ID: ${user.salesRepId}'),
      );
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: const Icon(Icons.card_giftcard_outlined, color: Colors.orange),
      title: const Text('Bạn có mã giới thiệu?'),
      subtitle: const Text('Nhập mã từ NVKD để nhận hỗ trợ tốt hơn.'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showReferralInputDialog(context),
    );
  }

  void _showReferralInputDialog(BuildContext context) {
    final profileCubit = context.read<ProfileCubit>();
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: profileCubit,
        child: AlertDialog(
          title: const Text('Nhập mã giới thiệu'),
          content: Form(
            key: formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: codeController,
                    decoration: const InputDecoration(labelText: 'Mã giới thiệu'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập mã' : null,
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
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('HỦY'),
              onPressed: () => Navigator.of(context).pop(),
            ),
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
}

class _ProfileForm extends StatefulWidget {
  final UserModel user;
  const _ProfileForm({required this.user});
  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  late final TextEditingController _displayNameController;
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.user.displayName);
  }

  @override
  void didUpdateWidget(covariant _ProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user.displayName != _displayNameController.text) {
      _displayNameController.text = widget.user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Thông tin cá nhân', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => setState(() => _isEditing = !_isEditing),
                    child: Text(_isEditing ? 'HỦY' : 'SỬA'),
                  )
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _displayNameController,
                  enabled: _isEditing,
                  decoration: InputDecoration(
                      labelText: 'Tên hiển thị',
                      border: const OutlineInputBorder(),
                      filled: !_isEditing,
                      fillColor: !_isEditing ? Colors.grey.shade100 : null
                  ),
                  validator: (value) {
                    if(_isEditing && (value == null || value.trim().isEmpty)) {
                      return 'Tên hiển thị không được để trống';
                    }
                    return null;
                  }
              ),
              const SizedBox(height: 16),
              TextFormField(
                  initialValue: widget.user.email,
                  enabled: false,
                  decoration: InputDecoration(
                      labelText: 'Email',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey.shade100
                  )
              ),
              if (_isEditing) ...[
                const SizedBox(height: 32),
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
                                  Future.delayed(const Duration(milliseconds: 50), () {
                                    context.read<ProfileCubit>().saveUserProfile();
                                    setState(() => _isEditing = false);
                                  });
                                }
                              },
                              child: const Text('LƯU THAY ĐỔI')
                          );
                        }
                    )
                )
              ]
            ]
        )
    );
  }
}

class _AddressSection extends StatelessWidget {
  final List<AddressModel> addresses;
  const _AddressSection({required this.addresses});

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sổ địa chỉ', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (addresses.isEmpty) const Center(child: Text('Bạn chưa có địa chỉ nào.'))
          else ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final address = addresses[index];
                return _AddressCard(address: address);
              }
          ),
          const SizedBox(height: 16),
          SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm địa chỉ mới'),
                  onPressed: () { _showAddressFormDialog(context); }
              )
          )
        ]
    );
  }
}

class _AddressCard extends StatelessWidget {
  final AddressModel address;
  const _AddressCard({required this.address});

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
                color: address.isDefault ? Theme.of(context).colorScheme.primary : Colors.transparent,
                width: 1.5
            )
        ),
        child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(address.recipientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(address.phoneNumber, style: TextStyle(color: Colors.grey.shade700))
                                ]
                            )
                        ),
                        Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey),
                                  onPressed: () { _showAddressFormDialog(context, address: address); }
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(),
                                  icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 20),
                                  onPressed: () {
                                    showDialog(
                                        context: context,
                                        builder: (dialogContext) => AlertDialog(
                                            title: const Text('Xác nhận xóa'),
                                            content: const Text('Bạn có chắc chắn muốn xóa địa chỉ này?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('HỦY')),
                                              TextButton(
                                                  onPressed: () {
                                                    context.read<ProfileCubit>().deleteAddress(address.id);
                                                    Navigator.of(dialogContext).pop();
                                                  },
                                                  child: Text('XÓA', style: TextStyle(color: Theme.of(context).colorScheme.error))
                                              )
                                            ]
                                        )
                                    );
                                  }
                              )
                            ]
                        )
                      ]
                  ),
                  const Divider(),
                  Text(address.street),
                  // --- THAY ĐỔI ---: Xóa hiển thị district
                  Text('${address.ward}, ${address.city}'),
                  const SizedBox(height: 8),
                  if (address.isDefault)
                    const Chip(
                        label: Text('Mặc định'),
                        backgroundColor: Colors.green,
                        labelStyle: TextStyle(color: Colors.white),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        visualDensity: VisualDensity(horizontal: 0.0, vertical: -4)
                    )
                  else Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                          onPressed: () { context.read<ProfileCubit>().setDefaultAddress(address.id); },
                          child: const Text('Đặt làm mặc định')
                      )
                  )
                ]
            )
        )
    );
  }
}

void _showAddressFormDialog(BuildContext context, {AddressModel? address}) {
  final profileCubit = context.read<ProfileCubit>();
  showDialog(context: context, builder: (_) => BlocProvider.value(value: profileCubit, child: _AddressFormDialog(address: address)));
}

class _AddressFormDialog extends StatefulWidget {
  final AddressModel? address;
  const _AddressFormDialog({this.address});

  @override
  State<_AddressFormDialog> createState() => _AddressFormDialogState();
}

class _AddressFormDialogState extends State<_AddressFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _streetController;
  late TextEditingController _wardController;
  // --- THAY ĐỔI ---: Xóa _districtController
  // late TextEditingController _districtController;
  late TextEditingController _cityController;
  late bool _isDefault;
  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.address?.recipientName ?? '');
    _phoneController = TextEditingController(text: widget.address?.phoneNumber ?? '');
    _streetController = TextEditingController(text: widget.address?.street ?? '');
    _wardController = TextEditingController(text: widget.address?.ward ?? '');
    // --- THAY ĐỔI ---: Xóa khởi tạo _districtController
    // _districtController = TextEditingController(text: widget.address?.district ?? '');
    _cityController = TextEditingController(text: widget.address?.city ?? '');
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _wardController.dispose();
    // --- THAY ĐỔI ---: Xóa dispose _districtController
    // _districtController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final newAddress = AddressModel(
          id: widget.address?.id,
          recipientName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          street: _streetController.text.trim(),
          ward: _wardController.text.trim(),
          // --- THAY ĐỔI ---: Xóa district khỏi newAddress
          // district: _districtController.text.trim(),
          city: _cityController.text.trim(),
          isDefault: _isDefault
      );
      if (_isEditing) {
        context.read<ProfileCubit>().updateAddress(newAddress);
      } else {
        context.read<ProfileCubit>().addAddress(newAddress);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text(_isEditing ? 'Sửa địa chỉ' : 'Thêm địa chỉ mới'),
        content: Form(
            key: _formKey,
            child: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField(controller: _nameController, label: 'Họ và tên'),
                      _buildTextField(controller: _phoneController, label: 'Số điện thoại', keyboardType: TextInputType.phone),
                      _buildTextField(controller: _streetController, label: 'Địa chỉ cụ thể (số nhà, tên đường)'),
                      _buildTextField(controller: _wardController, label: 'Phường/Xã'),
                      // --- THAY ĐỔI ---: Xóa TextFormField của Quận/Huyện
                      // _buildTextField(controller: _districtController, label: 'Quận/Huyện'),
                      _buildTextField(controller: _cityController, label: 'Tỉnh/Thành phố'),
                      SwitchListTile(
                          title: const Text('Đặt làm mặc định'),
                          value: _isDefault,
                          onChanged: (bool value) { setState(() { _isDefault = value; }); },
                          contentPadding: EdgeInsets.zero
                      )
                    ]
                )
            )
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('HỦY')),
          ElevatedButton(onPressed: _onSave, child: const Text('LƯU'))
        ]
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, TextInputType? keyboardType}) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextFormField(
            controller: controller,
            decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
            keyboardType: keyboardType,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label không được để trống';
              }
              return null;
            }
        )
    );
  }
}