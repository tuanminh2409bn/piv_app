import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart'; // Để lấy RegisterCubit
import 'package:piv_app/features/auth/presentation/bloc/register_cubit.dart';

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
        create: (_) => sl<RegisterCubit>(), // Cung cấp RegisterCubit
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

  @override
  void dispose() {
    _displayNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
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
          // Hiển thị thông báo đăng ký thành công
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: const Text('Đăng ký thành công!'), // Thông báo ngắn gọn hơn
                backgroundColor: Colors.green.shade700,
                duration: const Duration(seconds: 2), // Thời gian hiển thị SnackBar
              ),
            );
          // Sau khi hiển thị thông báo, đóng (pop) RegisterPage
          // và tất cả các trang phía trên nó cho đến màn hình đầu tiên.
          // AuthBloc và InitialScreenController sẽ đảm nhiệm việc hiển thị HomeScreen.
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const SizedBox(height: 24.0),
            _RegisterButton(),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Đã có tài khoản?"),
                TextButton(
                  onPressed: () {
                    // Quay lại trang Đăng nhập
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
}

// Widget _DisplayNameInput (không thay đổi)
class _DisplayNameInput extends StatelessWidget {
  final FocusNode focusNode;
  const _DisplayNameInput({super.key, required this.focusNode});

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
            hintText: 'Nhập tên của bạn',
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

// Widget _EmailInput (không thay đổi)
class _EmailInput extends StatelessWidget {
  final FocusNode focusNode;
  const _EmailInput({super.key, required this.focusNode});

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
            hintText: 'Nhập Email của bạn',
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

// Widget _PasswordInput (không thay đổi)
class _PasswordInput extends StatefulWidget {
  final FocusNode focusNode;
  const _PasswordInput({super.key, required this.focusNode});
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

// Widget _ConfirmPasswordInput (không thay đổi)
class _ConfirmPasswordInput extends StatefulWidget {
  final FocusNode focusNode;
  const _ConfirmPasswordInput({super.key, required this.focusNode});
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
            hintText: 'Nhập lại mật khẩu',
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
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_){
            if (state.isFormValid) {
              context.read<RegisterCubit>().signUpWithCredentials();
            }
          },
        );
      },
    );
  }
}

// Widget _RegisterButton (không thay đổi)
class _RegisterButton extends StatelessWidget {
  const _RegisterButton({super.key}); // Thêm super.key
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterCubit, RegisterState>(
      builder: (context, state) {
        return state.status == RegisterStatus.submitting
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
          onPressed: state.isFormValid
              ? () => context.read<RegisterCubit>().signUpWithCredentials()
              : null, // Disable nút nếu form không hợp lệ
          child: const Text('ĐĂNG KÝ'),
        );
      },
    );
  }
}
