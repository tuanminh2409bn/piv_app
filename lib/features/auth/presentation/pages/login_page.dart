// lib/features/auth/presentation/pages/login_page.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/core/theme/app_theme.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/auth/presentation/bloc/login_cubit.dart';
import 'package:piv_app/features/auth/presentation/bloc/social_sign_in_cubit.dart';
import 'package:piv_app/features/auth/presentation/pages/register_page.dart';
import 'package:piv_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'dart:io';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Nền trắng tinh khôi
      body: Stack(
        children: [
          // 1. Họa tiết nền (Lá cây / Đốm màu)
          Positioned.fill(
            child: CustomPaint(
              painter: _NatureBackgroundPainter(
                color1: AppTheme.primaryGreen.withValues(alpha: 0.1),
                color2: AppTheme.secondaryGreen.withValues(alpha: 0.05),
                accent: AppTheme.accentGold.withValues(alpha: 0.2),
              ),
            ),
          ),

          // 2. Nội dung chính
          Center(
            child: MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => sl<LoginCubit>()),
                BlocProvider(create: (_) => sl<SocialSignInCubit>()),
              ],
              child: const LoginForm(),
            ),
          ),
        ],
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
    return MultiBlocListener(
      listeners: [
        // 1. Lắng nghe AuthBloc (Để bắt trạng thái Pending Approval khi đăng nhập lại)
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAccountPending) {
               ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppTheme.primaryGreen, // Màu xanh thông báo
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 4),
                  ),
                );
            }
          },
        ),
        // 2. Lắng nghe SocialSignInCubit (Để bắt sự kiện đăng ký mới thành công)
        BlocListener<SocialSignInCubit, SocialSignInState>(
          listener: (context, state) {
            if (state.status == SocialSignInStatus.error) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage ?? 'Đăng nhập thất bại.'),
                    backgroundColor: AppTheme.errorRed,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
            } else if (state.status == SocialSignInStatus.success && state.isNewUser) {
               ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: const Text('Đăng ký thành công! Tài khoản của bạn đang chờ phê duyệt.'),
                    backgroundColor: AppTheme.primaryGreen,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 4),
                  ),
                );
            }
          },
        ),
        // 3. Lắng nghe LoginCubit (Lỗi đăng nhập thường)
        BlocListener<LoginCubit, LoginState>(
          listener: (context, state) {
            if (state.status == LoginStatus.error) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage ?? 'Lỗi đăng nhập không xác định.'),
                    backgroundColor: AppTheme.errorRed,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
            }
          },
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // --- LOGO & HEADER ---
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Image.asset(
                'assets/logo_piv.png',
                fit: BoxFit.contain,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            
            const SizedBox(height: 24),
            
            Text(
              'PHÂN BÓN PIV',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            
            Text(
              'Đồng hành cùng nhà nông',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textGrey,
                letterSpacing: 0.5,
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 48),

            // --- INPUT FIELDS ---
            _EmailInput(emailFocusNode: _emailFocusNode, passwordFocusNode: _passwordFocusNode)
                .animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0),
            const SizedBox(height: 16.0),
            _PasswordInput(passwordFocusNode: _passwordFocusNode)
                .animate().fadeIn(delay: 500.ms).slideX(begin: -0.1, end: 0),
            
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).push(ForgotPasswordPage.route()),
                child: const Text('Quên mật khẩu?'),
              ),
            ),

            const SizedBox(height: 24.0),
            
            const _LoginButton()
                .animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.9, 0.9)),

            const SizedBox(height: 32),

            // --- SOCIAL LOGIN (EQUAL SIZE) ---
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.2))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text('Hoặc đăng nhập với', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                ),
                Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.2))),
              ],
            ).animate().fadeIn(delay: 700.ms),
            
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google
                _SocialButton(
                  icon: Image.asset('assets/google_logo.png', height: 24),
                  onTap: () => context.read<SocialSignInCubit>().logInWithGoogle(),
                ),
                
                const SizedBox(width: 20),
                
                // Facebook
                _SocialButton(
                  icon: const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 28),
                  onTap: () => context.read<SocialSignInCubit>().logInWithFacebook(),
                ),

                // Apple (iOS only)
                if (Platform.isIOS) ...[
                  const SizedBox(width: 20),
                  _SocialButton(
                    icon: const Icon(Icons.apple, color: Colors.black, size: 28),
                    onTap: () => context.read<SocialSignInCubit>().logInWithApple(),
                  ),
                ],
              ],
            ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 32),

            // --- REGISTER ---
            const _GuestLoginButton(),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Chưa có tài khoản?", style: TextStyle(color: AppTheme.textGrey)),
                TextButton(
                  onPressed: () => Navigator.of(context).push(RegisterPage.route()),
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

// --- WIDGETS ---

class _SocialButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;

  const _SocialButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Center(child: icon),
      ),
    );
  }
}

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
            prefixIcon: const Icon(Icons.email_outlined),
            fillColor: Colors.grey.withValues(alpha: 0.05), // Nhạt hơn trên nền trắng
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (email) => context.read<LoginCubit>().emailChanged(email),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(passwordFocusNode),
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
            prefixIcon: const Icon(Icons.lock_outline),
            fillColor: Colors.grey.withValues(alpha: 0.05),
            suffixIcon: IconButton(
              icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _obscureText = !_obscureText),
            ),
          ),
          obscureText: _obscureText,
          onChanged: (password) => context.read<LoginCubit>().passwordChanged(password),
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
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: state.status == LoginStatus.submitting
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: context.watch<LoginCubit>().state.isFormValid
                      ? () => context.read<LoginCubit>().logInWithCredentials()
                      : null,
                  style: ElevatedButton.styleFrom(
                    elevation: 8,
                    shadowColor: AppTheme.primaryGreen.withValues(alpha: 0.4),
                  ),
                  child: const Text('ĐĂNG NHẬP'),
                ),
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
      listener: (context, state) {},
      builder: (context, state) {
        final isLoading = state.status == SocialSignInStatus.submitting && state.submissionProvider == SocialSignInProvider.guest;
        return isLoading
            ? const Center(child: CircularProgressIndicator())
            : OutlinedButton(
                onPressed: () => context.read<SocialSignInCubit>().logInAsGuest(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
                  foregroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Trải nghiệm không cần tài khoản'),
              );
      },
    );
  }
}

// --- BACKGROUND PAINTER ---
class _NatureBackgroundPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final Color accent;

  _NatureBackgroundPainter({required this.color1, required this.color2, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 1. Góc trên trái: Lá cây lớn mềm mại
    paint.color = color1;
    final path1 = Path();
    path1.moveTo(0, 0);
    path1.lineTo(0, size.height * 0.35);
    path1.quadraticBezierTo(size.width * 0.2, size.height * 0.3, size.width * 0.4, size.height * 0.15);
    path1.quadraticBezierTo(size.width * 0.6, 0, size.width * 0.7, 0);
    path1.close();
    canvas.drawPath(path1, paint);

    // 2. Góc dưới phải: Đồi nhỏ / Đất
    paint.color = color2;
    final path2 = Path();
    path2.moveTo(size.width, size.height);
    path2.lineTo(size.width, size.height * 0.75);
    path2.quadraticBezierTo(size.width * 0.7, size.height * 0.8, size.width * 0.5, size.height * 0.9);
    path2.quadraticBezierTo(size.width * 0.2, size.height, 0, size.height);
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, paint);
    
    // 3. Điểm nhấn: Các đốm tròn (Hạt giống/Phấn hoa)
    paint.color = accent;
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.15), 15, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.25), 8, paint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.85), 10, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}