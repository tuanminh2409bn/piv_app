import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'package:piv_app/app/app_bloc_observer.dart';
import 'package:piv_app/core/di/injection_container.dart' as di;
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/auth/presentation/pages/login_page.dart';
import 'package:piv_app/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:piv_app/features/main/presentation/pages/main_screen.dart';
import 'package:piv_app/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:piv_app/features/wishlist/presentation/bloc/wishlist_cubit.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_home_page.dart';
import 'package:piv_app/features/sales_rep/presentation/pages/sales_rep_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await di.initializeDependencies();
  await initializeDateFormatting('vi_VN', null);

  Bloc.observer = di.sl<AppBlocObserver>();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => di.sl<AuthBloc>()..add(AuthAppStarted())),
        BlocProvider(create: (context) => di.sl<CartCubit>()),
        BlocProvider(create: (context) => di.sl<WishlistCubit>()),
        BlocProvider(create: (context) => di.sl<ProfileCubit>()),
      ],
      child: MaterialApp(
        title: 'Phân Bón PIV',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            primarySwatch: Colors.green,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green.shade700),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF9F9F9),
            appBarTheme: const AppBarTheme(
              elevation: 1,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
            ),
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

        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('vi', 'VN'),
          Locale('en', 'US'),
        ],
        locale: const Locale('vi', 'VN'),
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
          if (state.user.isAdmin) {
            return const AdminHomePage();
          } else if (state.user.isSalesRep) {
            return const SalesRepHomePage();
          } else {
            return const MainScreen();
          }
        }
        else if (state is AuthUnauthenticated) {
          return const LoginPage();
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}