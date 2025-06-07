import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:piv_app/app/app_bloc_observer.dart';
import 'package:piv_app/core/di/injection_container.dart' as di;
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/cart/presentation/bloc/cart_cubit.dart';
// Import các trang cần thiết
import 'package:piv_app/features/home/presentation/pages/home_page.dart'; // ** DÒNG IMPORT QUAN TRỌNG **
import 'package:piv_app/features/auth/presentation/pages/login_page.dart';
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
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green.shade700, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                )
            ),
            textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)
                )
            )
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
          // Lệnh gọi này sẽ không còn báo lỗi
          return const HomePage();
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
