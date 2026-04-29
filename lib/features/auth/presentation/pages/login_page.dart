// lib/features/auth/presentation/pages/login_page.dart

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/core/theme/nature_background_painter.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/auth/presentation/bloc/login_cubit.dart';
import 'package:piv_app/features/auth/presentation/bloc/social_sign_in_cubit.dart';
import 'package:piv_app/features/auth/presentation/pages/register_page.dart';
import 'package:piv_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:piv_app/core/utils/platform_utils.dart';
import 'package:piv_app/common/widgets/responsive_wrapper.dart';
import 'package:piv_app/core/utils/responsive.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Responsive.isDesktop(context)
          ? const _WebLoginLayout()
          : const _MobileLoginLayout(),
    );
  }
}

class _MobileLoginLayout extends StatelessWidget {
  const _MobileLoginLayout();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: NatureBackgroundPainter(
              color1: AppTheme.primaryGreen.withValues(alpha: 0.15),
              color2: AppTheme.secondaryGreen.withValues(alpha: 0.1),
              accent: AppTheme.accentGold.withValues(alpha: 0.25),
            ),
          ),
        ),
        Center(
          child: ResponsiveWrapper(
            isForm: true,
            backgroundColor: Colors.transparent,
            showShadow: false,
            child: MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => sl<LoginCubit>()),
                BlocProvider(create: (_) => sl<SocialSignInCubit>()),
              ],
              child: const LoginForm(),
            ),
          ),
        ),
      ],
    );
  }
}

class _WebLoginLayout extends StatelessWidget {
  const _WebLoginLayout();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // PHẦN TRÁI: FORM ĐĂNG NHẬP
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: NatureBackgroundPainter(
                      color1: AppTheme.primaryGreen.withValues(alpha: 0.05),
                      color2: AppTheme.secondaryGreen.withValues(alpha: 0.03),
                      accent: AppTheme.accentGold.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 450),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                      child: MultiBlocProvider(
                        providers: [
                          BlocProvider(create: (_) => sl<LoginCubit>()),
                          BlocProvider(create: (_) => sl<SocialSignInCubit>()),
                        ],
                        child: const LoginForm(isWeb: true),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // PHẦN PHẢI: LOGO, SLOGAN VÀ BACKGROUND
        Expanded(
          flex: 6,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Ảnh nền nông nghiệp
              Image.asset(
                'assets/nongnghiep.png',
                fit: BoxFit.cover,
              ),
              // Lớp phủ mờ và màu sắc thương hiệu
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryGreen.withValues(alpha: 0.7),
                          AppTheme.secondaryGreen.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Nội dung Logo và Slogan
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          )
                        ],
                      ),
                      child: Image.asset('assets/logo_piv.png', height: 180),
                    ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 40),
                    const Text(
                      'PHÂN BÓN PIV',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 10)
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5, end: 0),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'Thấu hiểu nhà nông - Thấu hiểu cây trồng',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.5, end: 0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LoginForm extends StatefulWidget {
  final bool isWeb;
  const LoginForm({super.key, this.isWeb = false});

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
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Khi đăng nhập thành công, đóng trang Login để quay về trang chủ (InitialScreenController sẽ lo việc hiển thị MainScreen)
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: MultiBlocListener(
        listeners: [
          BlocListener<SocialSignInCubit, SocialSignInState>(
            listener: (context, state) {
              if (state.status == SocialSignInStatus.error && state.errorMessage != null) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(state.errorMessage!), backgroundColor: AppTheme.errorRed));
              }
            },
          ),
          BlocListener<LoginCubit, LoginState>(
            listener: (context, state) {
              if (state.status == LoginStatus.success) {
                // Đóng màn hình đăng nhập ngay khi Cubit báo thành công
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
              if (state.status == LoginStatus.error && state.errorMessage != null) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(state.errorMessage!), backgroundColor: AppTheme.errorRed));
              }
            },
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.isWeb) _Header(),
            if (widget.isWeb) ...[
               const Text(
                'CHÀO MỪNG TRỞ LẠI',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, letterSpacing: 2),
              ).animate().fadeIn(),
              const SizedBox(height: 8),
              const Text(
                'Đăng nhập tài khoản',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 40),
            ],
            const _LoginFormContent(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Hero(
          tag: 'app_logo',
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: Image.asset('assets/logo_piv.png', height: 80),
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        const Text(
          'PHÂN BÓN PIV',
          style: TextStyle(color: AppTheme.primaryGreen, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.5, end: 0),
        const Text(
          'Đồng hành cùng nhà nông',
          style: TextStyle(color: AppTheme.textGrey, fontSize: 16, fontStyle: FontStyle.italic),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }
}

class _LoginFormContent extends StatefulWidget {
  const _LoginFormContent();

  @override
  State<_LoginFormContent> createState() => _LoginFormContentState();
}

class _LoginFormContentState extends State<_LoginFormContent> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email hoặc Số điện thoại',
              prefixIcon: Icon(Icons.person_outline),
              filled: true,
              fillColor: Color(0xFFF5F7F9),
              border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            onChanged: (v) => context.read<LoginCubit>().emailChanged(v),
            validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập thông tin' : null,
          ),
          const SizedBox(height: 16),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline),
              filled: true,
              fillColor: const Color(0xFFF5F7F9),
              border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            onChanged: (v) => context.read<LoginCubit>().passwordChanged(v),
            validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
          ),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).push(ForgotPasswordPage.route()),
              child: const Text('Quên mật khẩu?'),
            ),
          ),
          const SizedBox(height: 16),

          // Login Button
          BlocBuilder<LoginCubit, LoginState>(
            builder: (context, state) {
              return ElevatedButton(
                onPressed: state.status == LoginStatus.submitting
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          context.read<LoginCubit>().logInWithCredentials();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: state.status == LoginStatus.submitting
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Text('ĐĂNG NHẬP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              );
            },
          ),

          const SizedBox(height: 24),
          const _DividerWithText('Hoặc đăng nhập với'),
          const SizedBox(height: 24),

          // Social Login
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SocialButton(
                icon: Image.asset('assets/google_logo.png', height: 24),
                onTap: () => context.read<SocialSignInCubit>().logInWithGoogle(),
              ),
              const SizedBox(width: 20),
              _SocialButton(
                icon: const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 28),
                onTap: () => context.read<SocialSignInCubit>().logInWithFacebook(),
              ),
              if (PlatformUtils.isIOS) ...[
                const SizedBox(width: 20),
                _SocialButton(
                  icon: const Icon(Icons.apple, color: Colors.black, size: 28),
                  onTap: () => context.read<SocialSignInCubit>().logInWithApple(),
                ),
              ],
            ],
          ),

          const SizedBox(height: 32),
          
          // Guest Login Button
          BlocBuilder<LoginCubit, LoginState>(
            builder: (context, state) {
              return OutlinedButton.icon(
                onPressed: state.status == LoginStatus.submitting ? null : () => context.read<LoginCubit>().logInAnonymously(),
                icon: const Icon(Icons.person_outline),
                label: const Text('XEM VỚI TƯ CÁCH KHÁCH', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: const BorderSide(color: AppTheme.primaryGreen),
                  foregroundColor: AppTheme.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Chưa có tài khoản? '),
              GestureDetector(
                onTap: () => Navigator.of(context).push(RegisterPage.route()),
                child: const Text('Đăng ký ngay', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart);
  }
}

class _SocialButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;
  const _SocialButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
        child: icon,
      ),
    );
  }
}

class _DividerWithText extends StatelessWidget {
  final String text;
  const _DividerWithText(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(text, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }
}
