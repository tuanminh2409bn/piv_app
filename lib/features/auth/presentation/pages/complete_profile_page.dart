// lib/features/auth/presentation/pages/complete_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:intl/intl.dart';

class CompleteProfilePage extends StatefulWidget {
  final UserModel user;
  const CompleteProfilePage({super.key, required this.user});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _idCardController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.user.displayName);
    _phoneNumberController = TextEditingController(text: widget.user.phoneNumber);
    _idCardController = TextEditingController(text: widget.user.idCardOrTaxId);
    _dobController = TextEditingController(text: widget.user.dob);
    _addressController = TextEditingController(text: widget.user.currentAddress);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneNumberController.dispose();
    _idCardController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final updatedUser = widget.user.copyWith(
        displayName: _displayNameController.text,
        phoneNumber: _phoneNumberController.text,
        idCardOrTaxId: _idCardController.text,
        dob: _dobController.text,
        currentAddress: _addressController.text,
      );
      
      context.read<ProfileCubit>().updateProfileDirect(updatedUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state.status == ProfileStatus.success) {
          final isAlreadyActive = widget.user.status == 'active';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAlreadyActive 
                ? 'Cập nhật hồ sơ thành công!' 
                : 'Cập nhật hồ sơ thành công! Tài khoản của bạn đang chờ phê duyệt.'),
            ),
          );
          // Refresh auth state
          context.read<AuthBloc>().add(AuthUserRefreshRequested());
        } else if (state.status == ProfileStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Lỗi cập nhật hồ sơ')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hoàn thiện hồ sơ'),
          actions: [
            IconButton(
              onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Thông tin của bạn chưa đầy đủ. Vui lòng bổ sung để tiếp tục.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(labelText: 'Họ và tên *', prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập họ tên' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(labelText: 'Số điện thoại *', prefixIcon: Icon(Icons.phone_outlined)),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập số điện thoại' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _idCardController,
                  decoration: const InputDecoration(labelText: 'CCCD hoặc Mã số thuế *', prefixIcon: Icon(Icons.badge_outlined)),
                  validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập CCCD/MST' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  decoration: const InputDecoration(
                    labelText: 'Ngày tháng năm sinh *', 
                    hintText: 'Chọn ngày sinh', 
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Vui lòng chọn ngày sinh' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Địa chỉ hiện tại *', prefixIcon: Icon(Icons.location_on_outlined)),
                  validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                ),
                const SizedBox(height: 32),
                BlocBuilder<ProfileCubit, ProfileState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state.status == ProfileStatus.updating ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: state.status == ProfileStatus.updating
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('XÁC NHẬN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32), // Khoảng trống ở cuối để không bị che bởi thanh điều hướng
              ],
            ),
          ),
        ),
      ),
    );
  }
}
