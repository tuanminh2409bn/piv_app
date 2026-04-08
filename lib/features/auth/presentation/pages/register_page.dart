//lib/features/auth/presentation/pages/register_page.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/auth/presentation/bloc/register_cubit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/core/theme/nature_background_painter.dart';
import 'package:piv_app/common/widgets/responsive_wrapper.dart';
import 'package:piv_app/core/utils/responsive.dart';

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

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const RegisterPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. HỌA TIẾT NỀN - Toàn màn hình
          Positioned.fill(
            child: CustomPaint(
              painter: NatureBackgroundPainter(
                color1: AppTheme.primaryGreen.withValues(alpha: 0.15),
                color2: AppTheme.secondaryGreen.withValues(alpha: 0.1),
                accent: AppTheme.accentGold.withValues(alpha: 0.25),
              ),
            ),
          ),

          // 2. Nội dung chính
          Center(
            child: ResponsiveWrapper(
              // Tăng maxWidth cho web khi dùng form ngang
              maxWidth: Responsive.isMobile(context) ? 600 : 900,
              isForm: true,
              backgroundColor: Colors.transparent, 
              showShadow: false,
              child: BlocProvider(
                create: (_) => sl<RegisterCubit>(),
                child: const RegisterForm(),
              ),
            ),
          ),
          
          // Nút quay lại
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 8.0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _displayNameFocusNode = FocusNode();
  final _phoneNumberFocusNode = FocusNode();
  final _idCardOrTaxIdFocusNode = FocusNode();
  final _dobFocusNode = FocusNode();
  final _currentAddressFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _referralCodeFocusNode = FocusNode();

  @override
  void dispose() {
    _displayNameFocusNode.dispose();
    _phoneNumberFocusNode.dispose();
    _idCardOrTaxIdFocusNode.dispose();
    _dobFocusNode.dispose();
    _currentAddressFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _referralCodeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = !Responsive.isMobile(context);

    return BlocListener<RegisterCubit, RegisterState>(
      listener: (context, state) {
        if (state.status == RegisterStatus.error) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Lỗi đăng ký không xác định.'),
                backgroundColor: AppTheme.errorRed,
              ),
            );
        } else if (state.status == RegisterStatus.success) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Đăng ký thành công! Tài khoản của bạn đang chờ phê duyệt.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 4),
              ),
            );
          Navigator.of(context).pop();
        }
      },
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Tạo tài khoản mới',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vui lòng điền đầy đủ thông tin bên dưới',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textGrey),
                ),
                const SizedBox(height: 32.0),

                if (isWide) ...[
                  // Layout 2 cột cho Web
                  Row(
                    children: [
                      Expanded(child: _DisplayNameInput(focusNode: _displayNameFocusNode)),
                      const SizedBox(width: 16),
                      Expanded(child: _PhoneNumberInput(focusNode: _phoneNumberFocusNode)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _IdCardOrTaxIdInput(focusNode: _idCardOrTaxIdFocusNode)),
                      const SizedBox(width: 16),
                      Expanded(child: _DobInput(focusNode: _dobFocusNode)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _CurrentAddressInput(focusNode: _currentAddressFocusNode),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _EmailInput(focusNode: _emailFocusNode)),
                      const SizedBox(width: 16),
                      Expanded(child: _ReferralCodeInput(focusNode: _referralCodeFocusNode)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _PasswordInput(focusNode: _passwordFocusNode)),
                      const SizedBox(width: 16),
                      Expanded(child: _ConfirmPasswordInput(focusNode: _confirmPasswordFocusNode)),
                    ],
                  ),
                ] else ...[
                  // Layout 1 cột cho Mobile
                  _DisplayNameInput(focusNode: _displayNameFocusNode),
                  const SizedBox(height: 16.0),
                  _PhoneNumberInput(focusNode: _phoneNumberFocusNode),
                  const SizedBox(height: 16.0),
                  _IdCardOrTaxIdInput(focusNode: _idCardOrTaxIdFocusNode),
                  const SizedBox(height: 16.0),
                  _DobInput(focusNode: _dobFocusNode),
                  const SizedBox(height: 16.0),
                  _CurrentAddressInput(focusNode: _currentAddressFocusNode),
                  const SizedBox(height: 16.0),
                  _EmailInput(focusNode: _emailFocusNode),
                  const SizedBox(height: 16.0),
                  _PasswordInput(focusNode: _passwordFocusNode),
                  const SizedBox(height: 16.0),
                  _ConfirmPasswordInput(focusNode: _confirmPasswordFocusNode),
                  const SizedBox(height: 16.0),
                  _ReferralCodeInput(focusNode: _referralCodeFocusNode),
                ],

                const SizedBox(height: 32.0),
                const _RegisterButton(),
                const SizedBox(height: 24.0),
                _buildTermsAndPolicyText(context),
                const SizedBox(height: 24.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Đã có tài khoản? "),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Đăng nhập ngay',
                        style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsAndPolicyText(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: 'Bằng việc đăng ký, bạn đồng ý với ',
        style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
        children: <TextSpan>[
          TextSpan(
            text: 'Điều khoản Dịch vụ',
            style: const TextStyle(
              color: AppTheme.primaryGreen,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.bold,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _launchURL(context, 'https://tuanminh2409bn.github.io/piv-terms/');
              },
          ),
          const TextSpan(text: ' và '),
          TextSpan(
            text: 'Chính sách Bảo mật',
            style: const TextStyle(
              color: AppTheme.primaryGreen,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.bold,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _launchURL(context, 'https://tuanminh2409bn.github.io/piv-privacy/');
              },
          ),
          const TextSpan(text: ' của chúng tôi.'),
        ],
      ),
    );
  }
}


class _DisplayNameInput extends StatelessWidget {
  final FocusNode focusNode;
  const _DisplayNameInput({required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterCubit, RegisterState>(
      buildWhen: (previous, current) => previous.displayName != current.displayName,
      builder: (context, state) {
        return TextFormField(
          initialValue: state.displayName,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Họ và tên *',
            prefixIcon: Icon(Icons.person_outline),
          ),
          keyboardType: TextInputType.name,
          onChanged: (value) {
            context.read<RegisterCubit>().displayNameChanged(value);
          },
          textInputAction: TextInputAction.next,
        );
      },
    );
  }
}

class _PhoneNumberInput extends StatelessWidget {
  final FocusNode focusNode;
  const _PhoneNumberInput({required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterCubit, RegisterState>(
      buildWhen: (previous, current) => previous.phoneNumber != current.phoneNumber,
      builder: (context, state) {
        return TextFormField(
          initialValue: state.phoneNumber,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Số điện thoại *',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          keyboardType: TextInputType.phone,
          onChanged: (value) {
            context.read<RegisterCubit>().phoneNumberChanged(value);
          },
          textInputAction: TextInputAction.next,
        );
      },
    );
  }
}

class _IdCardOrTaxIdInput extends StatelessWidget {
  final FocusNode focusNode;
  const _IdCardOrTaxIdInput({required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterCubit, RegisterState>(
      buildWhen: (previous, current) => previous.idCardOrTaxId != current.idCardOrTaxId,
      builder: (context, state) {
        return TextFormField(
          initialValue: state.idCardOrTaxId,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'CCCD hoặc MST *',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          onChanged: (value) {
            context.read<RegisterCubit>().idCardOrTaxIdChanged(value);
          },
          textInputAction: TextInputAction.next,
        );
      },
    );
  }
}

class _DobInput extends StatefulWidget {
  final FocusNode focusNode;
  const _DobInput({required this.focusNode});

  @override
  State<_DobInput> createState() => _DobInputState();
}

class _DobInputState extends State<_DobInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
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
      final formattedDate = DateFormat('dd/MM/yyyy').format(picked);
      _controller.text = formattedDate;
      context.read<RegisterCubit>().dobChanged(formattedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterCubit, RegisterState>(
      buildWhen: (previous, current) => previous.dob != current.dob,
      builder: (context, state) {
        if (state.dob != _controller.text) {
          _controller.text = state.dob;
        }
        return TextFormField(
          controller: _controller,
          focusNode: widget.focusNode,
          readOnly: true,
          onTap: () => _selectDate(context),
          decoration: const InputDecoration(
            labelText: 'Ngày sinh *',
            hintText: 'Chọn ngày sinh',
            prefixIcon: Icon(Icons.calendar_today_outlined),
            suffixIcon: Icon(Icons.arrow_drop_down),
          ),
          textInputAction: TextInputAction.next,
        );
      },
    );
  }
}

class _CurrentAddressInput extends StatelessWidget {
  final FocusNode focusNode;
  const _CurrentAddressInput({required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterCubit, RegisterState>(
      buildWhen: (previous, current) => previous.currentAddress != current.currentAddress,
      builder: (context, state) {
        return TextFormField(
          initialValue: state.currentAddress,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Địa chỉ hiện tại *',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          onChanged: (value) {
            context.read<RegisterCubit>().currentAddressChanged(value);
          },
          textInputAction: TextInputAction.next,
        );
      },
    );
  }
}

class _EmailInput extends StatelessWidget {
  final FocusNode focusNode;
  const _EmailInput({required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterCubit, RegisterState>(
      buildWhen: (previous, current) => previous.email != current.email,
      builder: (context, state) {
        return TextFormField(
          initialValue: state.email,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Email (Tùy chọn)',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) {
            context.read<RegisterCubit>().emailChanged(value);
          },
          textInputAction: TextInputAction.next,
        );
      },
    );
  }
}

class _PasswordInput extends StatefulWidget {
  final FocusNode focusNode;
  const _PasswordInput({required this.focusNode});
  @override
  State<_PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<_PasswordInput> {
  bool _obscureText = true;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterCubit, RegisterState>(
      buildWhen: (previous, current) => previous.password != current.password,
      builder: (context, state) {
        return TextFormField(
          initialValue: state.password,
          focusNode: widget.focusNode,
          decoration: InputDecoration(
            labelText: 'Mật khẩu *',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _obscureText = !_obscureText),
            ),
            errorText: state.password.isNotEmpty && state.password.length < 6
                ? 'Ít nhất 6 ký tự'
                : null,
          ),
          obscureText: _obscureText,
          onChanged: (value) {
            context.read<RegisterCubit>().passwordChanged(value);
          },
          textInputAction: TextInputAction.next,
        );
      },
    );
  }
}

class _ConfirmPasswordInput extends StatefulWidget {
  final FocusNode focusNode;
  const _ConfirmPasswordInput({required this.focusNode});
  @override
  State<_ConfirmPasswordInput> createState() => _ConfirmPasswordInputState();
}

class _ConfirmPasswordInputState extends State<_ConfirmPasswordInput> {
  bool _obscureText = true;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterCubit, RegisterState>(
      buildWhen: (previous, current) => previous.confirmPassword != current.confirmPassword || previous.password != current.password,
      builder: (context, state) {
        return TextFormField(
          initialValue: state.confirmPassword,
          focusNode: widget.focusNode,
          decoration: InputDecoration(
            labelText: 'Xác nhận mật khẩu *',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _obscureText = !_obscureText),
            ),
            errorText: state.confirmPassword.isNotEmpty && !state.passwordsMatch
                ? 'Mật khẩu không khớp'
                : null,
          ),
          obscureText: _obscureText,
          onChanged: (value) {
            context.read<RegisterCubit>().confirmPasswordChanged(value);
          },
          textInputAction: TextInputAction.next,
        );
      },
    );
  }
}

class _ReferralCodeInput extends StatelessWidget {
  final FocusNode focusNode;
  const _ReferralCodeInput({required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterCubit, RegisterState>(
      buildWhen: (previous, current) => previous.referralCode != current.referralCode,
      builder: (context, state) {
        return TextFormField(
          initialValue: state.referralCode,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Mã giới thiệu',
            prefixIcon: Icon(Icons.card_giftcard_outlined),
          ),
          onChanged: (value) {
            context.read<RegisterCubit>().referralCodeChanged(value);
          },
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_){
            if (context.read<RegisterCubit>().state.isFormValid) {
              context.read<RegisterCubit>().signUpWithCredentials();
            }
          },
        );
      },
    );
  }
}

class _RegisterButton extends StatelessWidget {
  const _RegisterButton();
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterCubit, RegisterState>(
      builder: (context, state) {
        return state.status == RegisterStatus.submitting
            ? const Center(child: CircularProgressIndicator())
            : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.isFormValid
                      ? () => context.read<RegisterCubit>().signUpWithCredentials()
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ĐĂNG KÝ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              );
      },
    );
  }
}
