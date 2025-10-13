// lib/features/auth/presentation/pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/auth/presentation/bloc/login_cubit.dart';
import 'package:piv_app/features/auth/presentation/bloc/social_sign_in_cubit.dart';
import 'package:piv_app/features/auth/presentation/pages/register_page.dart';
import 'dart:io';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng Nhập PIV'),
        centerTitle: true,
      ),
      body: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => sl<LoginCubit>()),
          BlocProvider(create: (_) => sl<SocialSignInCubit>()),
        ],
        child: const LoginForm(),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state.status == LoginStatus.error) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Lỗi đăng nhập không xác định.'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Chào mừng!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đăng nhập để tiếp tục',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 48.0),
            _EmailInput(emailFocusNode: _emailFocusNode, passwordFocusNode: _passwordFocusNode),
            const SizedBox(height: 16.0),
            _PasswordInput(passwordFocusNode: _passwordFocusNode),
            const SizedBox(height: 24.0),
            const _LoginButton(),
            const SizedBox(height: 16.0),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('HOẶC', style: TextStyle(color: Colors.grey.shade600)),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            const _GoogleLoginButton(),
            const SizedBox(height: 12),
            const _FacebookLoginButton(),
            if (Platform.isIOS) ...[
              const SizedBox(height: 12),
              const _AppleLoginButton(),
            ],
            const SizedBox(height: 16.0),
            const _GuestLoginButton(),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Chưa có tài khoản?"),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(RegisterPage.route());
                  },
                  child: const Text('Đăng ký ngay'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ... (_EmailInput, _PasswordInput, _LoginButton giữ nguyên)
class _EmailInput extends StatelessWidget {
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  const _EmailInput({required this.emailFocusNode, required this.passwordFocusNode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) => previous.email != current.email,
      builder: (context, state) {
        return TextFormField(
          initialValue: state.email,
          focusNode: emailFocusNode,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'Nhập Email của bạn',
            prefixIcon: const Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (email) {
            context.read<LoginCubit>().emailChanged(email);
          },
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(passwordFocusNode);
          },
        );
      },
    );
  }
}

class _PasswordInput extends StatefulWidget {
  final FocusNode passwordFocusNode;
  const _PasswordInput({required this.passwordFocusNode});

  @override
  State<_PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<_PasswordInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) => previous.password != current.password,
      builder: (context, state) {
        return TextFormField(
          initialValue: state.password,
          focusNode: widget.passwordFocusNode,
          decoration: InputDecoration(
            labelText: 'Mật khẩu',
            hintText: 'Nhập mật khẩu của bạn',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
          obscureText: _obscureText,
          onChanged: (password) {
            context.read<LoginCubit>().passwordChanged(password);
          },
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) {
            if (context.read<LoginCubit>().state.isFormValid) {
              context.read<LoginCubit>().logInWithCredentials();
            }
          },
        );
      },
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        return state.status == LoginStatus.submitting
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
          onPressed: context.watch<LoginCubit>().state.isFormValid
              ? () => context.read<LoginCubit>().logInWithCredentials()
              : null,
          child: const Text('ĐĂNG NHẬP'),
        );
      },
    );
  }
}

class _GoogleLoginButton extends StatelessWidget {
  const _GoogleLoginButton();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SocialSignInCubit, SocialSignInState>(
      listener: (context, state) {
        if (state.status == SocialSignInStatus.error && state.submissionProvider == SocialSignInProvider.google) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage ?? 'Đăng nhập Google thất bại.')));
        } else if (state.status == SocialSignInStatus.success && state.isNewUser) {
          // CHỈ HIỂN THỊ KHI ĐĂNG KÝ MỚI THÀNH CÔNG
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
              content: Text('Đăng ký thành công! Tài khoản của bạn đang chờ phê duyệt.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ));
        }
      },
      builder: (context, state) {
        final isLoading = state.status == SocialSignInStatus.submitting && state.submissionProvider == SocialSignInProvider.google;
        return isLoading
            ? const Center(child: CircularProgressIndicator())
            : OutlinedButton.icon(
          icon: Image.asset('assets/google_logo.png', height: 22.0),
          label: const Text('Đăng nhập với Google', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
          onPressed: () => context.read<SocialSignInCubit>().logInWithGoogle(),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey.shade300),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }
}

class _FacebookLoginButton extends StatelessWidget {
  const _FacebookLoginButton();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SocialSignInCubit, SocialSignInState>(
      listener: (context, state) {
        if (state.status == SocialSignInStatus.error && state.submissionProvider == SocialSignInProvider.facebook) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage ?? 'Đăng nhập Facebook thất bại.')));
        } else if (state.status == SocialSignInStatus.success && state.isNewUser) {
          // CHỈ HIỂN THỊ KHI ĐĂNG KÝ MỚI THÀNH CÔNG
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
              content: Text('Đăng ký thành công! Tài khoản của bạn đang chờ phê duyệt.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ));
        }
      },
      builder: (context, state) {
        final isLoading = state.status == SocialSignInStatus.submitting && state.submissionProvider == SocialSignInProvider.facebook;
        return isLoading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton.icon(
          icon: const Icon(Icons.facebook, color: Colors.white),
          label: const Text('Tiếp tục với Facebook'),
          onPressed: () => context.read<SocialSignInCubit>().logInWithFacebook(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1877F2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }
}

class _AppleLoginButton extends StatelessWidget {
  const _AppleLoginButton();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SocialSignInCubit, SocialSignInState>(
      listener: (context, state) {
        if (state.status == SocialSignInStatus.error && state.submissionProvider == SocialSignInProvider.apple) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage ?? 'Đăng nhập Apple thất bại.')));
        } else if (state.status == SocialSignInStatus.success && state.isNewUser) {
          // CHỈ HIỂN THỊ KHI ĐĂNG KÝ MỚI THÀNH CÔNG
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
              content: Text('Đăng ký thành công! Tài khoản của bạn đang chờ phê duyệt.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ));
        }
      },
      builder: (context, state) {
        final isLoading = state.status == SocialSignInStatus.submitting && state.submissionProvider == SocialSignInProvider.apple;
        return isLoading
            ? const Center(child: CircularProgressIndicator())
            : SignInWithAppleButton(
          onPressed: () => context.read<SocialSignInCubit>().logInWithApple(),
          style: SignInWithAppleButtonStyle.black,
          borderRadius: const BorderRadius.all(Radius.circular(12.0)),
          height: 48,
        );
      },
    );
  }
}

class _GuestLoginButton extends StatelessWidget {
  const _GuestLoginButton();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SocialSignInCubit, SocialSignInState>(
      listener: (context, state) {
        if (state.status == SocialSignInStatus.error && state.submissionProvider == SocialSignInProvider.guest) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(state.errorMessage ?? 'Không thể vào với tư cách khách.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ));
        }
      },
      builder: (context, state) {
        final isLoading = state.status == SocialSignInStatus.submitting && state.submissionProvider == SocialSignInProvider.guest;
        return isLoading
            ? const Center(child: CircularProgressIndicator())
            : OutlinedButton(
          onPressed: () => context.read<SocialSignInCubit>().logInAsGuest(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Trải nghiệm ứng dụng (Không cần tài khoản)'),
        );
      },
    );
  }
}