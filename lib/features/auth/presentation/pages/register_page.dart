//lib/features/auth/presentation/pages/register_page.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/auth/presentation/bloc/register_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> _launchURL(BuildContext context, String urlString) async {
  final Uri url = Uri.parse(urlString);
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Không thể mở đường dẫn: $urlString')),
    );
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
      appBar: AppBar(
        title: const Text('Đăng Ký Tài Khoản'),
        centerTitle: true,
      ),
      body: BlocProvider(
        create: (_) => sl<RegisterCubit>(),
        child: const RegisterForm(),
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
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _referralCodeFocusNode = FocusNode();

  @override
  void dispose() {
    _displayNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _referralCodeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegisterCubit, RegisterState>(
      listener: (context, state) {
        if (state.status == RegisterStatus.error) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Lỗi đăng ký không xác định.'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
        } else if (state.status == RegisterStatus.success) {
          // --- NỘI DUNG THÔNG BÁO ĐÃ ĐƯỢC CẬP NHẬT ---
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Đăng ký thành công! Tài khoản của bạn đang chờ phê duyệt.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 4), // Tăng thời gian hiển thị
              ),
            );
          // ---------------------------------------------
          Navigator.of(context).pop(); // Quay về trang đăng nhập
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: <Widget>[
            Text(
              'Tạo tài khoản mới',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng điền thông tin bên dưới',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32.0),
            _DisplayNameInput(focusNode: _displayNameFocusNode),
            const SizedBox(height: 16.0),
            _EmailInput(focusNode: _emailFocusNode),
            const SizedBox(height: 16.0),
            _PasswordInput(focusNode: _passwordFocusNode),
            const SizedBox(height: 16.0),
            _ConfirmPasswordInput(focusNode: _confirmPasswordFocusNode),
            const SizedBox(height: 16.0),
            _ReferralCodeInput(focusNode: _referralCodeFocusNode),
            const SizedBox(height: 24.0),
            const _RegisterButton(),
            const SizedBox(height: 24.0),
            _buildTermsAndPolicyText(context),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Đã có tài khoản?"),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Đăng nhập ngay'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsAndPolicyText(BuildContext context) {
    final theme = Theme.of(context);
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: 'Bằng việc đăng ký, bạn đồng ý với ',
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        children: <TextSpan>[
          TextSpan(
            text: 'Điều khoản Dịch vụ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _launchURL(context, 'https://tuanminh2409bn.github.io/piv-terms/');
              },
          ),
          const TextSpan(text: ' và '),
          TextSpan(
            text: 'Chính sách Bảo mật',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
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
            labelText: 'Tên hiển thị (Tùy chọn)',
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
            labelText: 'Email *',
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
            hintText: 'Ít nhất 6 ký tự',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _obscureText = !_obscureText),
            ),
            errorText: state.password.isNotEmpty && state.password.length < 6
                ? 'Mật khẩu phải có ít nhất 6 ký tự'
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
            labelText: 'Mã giới thiệu (Tùy chọn)',
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
            : ElevatedButton(
          onPressed: state.isFormValid
              ? () => context.read<RegisterCubit>().signUpWithCredentials()
              : null,
          child: const Text('ĐĂNG KÝ'),
        );
      },
    );
  }
}