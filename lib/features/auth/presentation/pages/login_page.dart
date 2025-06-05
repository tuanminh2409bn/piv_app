import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart'; // Để lấy LoginCubit từ Service Locator
import 'package:piv_app/features/auth/presentation/bloc/login_cubit.dart'; // Import LoginCubit và LoginState
// Import RegisterPage để điều hướng
import 'package:piv_app/features/auth/presentation/pages/register_page.dart';

// Lớp LoginPage là một StatelessWidget vì nó không quản lý trạng thái trực tiếp.
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
      body: BlocProvider(
        create: (_) => sl<LoginCubit>(),
        child: const LoginForm(),
      ),
    );
  }
}

// LoginForm là một StatefulWidget.
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
              'Chào mừng trở lại!',
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
            _EmailInput( // Sử dụng widget _EmailInput
              emailFocusNode: _emailFocusNode,
              passwordFocusNode: _passwordFocusNode,
            ),
            const SizedBox(height: 16.0),
            _PasswordInput( // Sử dụng widget _PasswordInput
              passwordFocusNode: _passwordFocusNode,
            ),
            const SizedBox(height: 24.0),
            const _LoginButton(), // Sử dụng widget _LoginButton
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

// ĐỊNH NGHĨA _EmailInput NHƯ MỘT CLASS RIÊNG BIỆT Ở TOP-LEVEL (CÙNG CẤP VỚI LoginPage)
class _EmailInput extends StatelessWidget {
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  const _EmailInput({
    // super.key, // super.key có thể thêm nếu cần, nhưng không bắt buộc cho private widget
    required this.emailFocusNode,
    required this.passwordFocusNode,
  });

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
            hintText: 'Nhập Email của bạn',
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

// ĐỊNH NGHĨA _PasswordInput NHƯ MỘT CLASS RIÊNG BIỆT Ở TOP-LEVEL
class _PasswordInput extends StatefulWidget {
  final FocusNode passwordFocusNode;
  const _PasswordInput({
    // super.key,
    required this.passwordFocusNode,
  });

  @override
  State<_PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<_PasswordInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) => previous.password != current.password || previous.status != current.status,
      builder: (context, state) {
        return TextFormField(
          initialValue: state.password,
          focusNode: widget.passwordFocusNode,
          decoration: InputDecoration(
            labelText: 'Mật khẩu',
            hintText: 'Nhập mật khẩu của bạn',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              ),
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
            if (state.isFormValid) {
              context.read<LoginCubit>().logInWithCredentials();
            }
          },
        );
      },
    );
  }
}

// ĐỊNH NGHĨA _LoginButton NHƯ MỘT CLASS RIÊNG BIỆT Ở TOP-LEVEL
class _LoginButton extends StatelessWidget {
  const _LoginButton({super.key}); // Thêm super.key ở đây

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) => previous.status != current.status || previous.isFormValid != current.isFormValid,
      builder: (context, state) {
        return state.status == LoginStatus.submitting
            ? const Center(child: CircularProgressIndicator(color: Colors.green))
            : ElevatedButton(
          onPressed: state.isFormValid
              ? () => context.read<LoginCubit>().logInWithCredentials()
              : null,
          child: const Text('ĐĂNG NHẬP'),
        );
      },
    );
  }
}
