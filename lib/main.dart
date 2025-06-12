import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:piv_app/app/app_bloc_observer.dart';
import 'package:piv_app/core/di/injection_container.dart' as di;
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:piv_app/features/home/presentation/pages/home_page.dart';
import 'package:piv_app/features/auth/presentation/pages/login_page.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_home_page.dart'; // Import trang Admin
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await di.initializeDependencies();
  await initializeDateFormatting('vi_VN', null);

  Bloc.observer = AppBlocObserver();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => di.sl<AuthBloc>()..add(AuthAppStarted()),
        ),
        BlocProvider(
          create: (context) => di.sl<CartCubit>(),
        ),
      ],
      child: MaterialApp(
        title: 'Phân Bón PIV',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green.shade700),
          useMaterial3: true,
          // ... (theme data không đổi)
        ),
        home: const InitialScreenController(),
      ),
    );
  }
}

class InitialScreenController extends StatelessWidget {
  const InitialScreenController({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          // ** KIỂM TRA VAI TRÒ NGƯỜI DÙNG Ở ĐÂY **
          if (state.user.isAdmin) {
            // Nếu là admin, điều hướng đến trang Admin
            return const AdminHomePage();
          } else {
            // Nếu là người dùng thường, điều hướng đến trang chủ
            return const HomePage();
          }
        }
        else if (state is AuthUnauthenticated) {
          return const LoginPage();
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: Colors.green)),
        );
      },
    );
  }
}

