import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:piv_app/core/services/notification_service.dart';
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

// Tách logic khởi tạo ra một hàm riêng
Future<void> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await di.initializeDependencies();
  await initializeDateFormatting('vi_VN', null);
  await di.sl<NotificationService>().initNotifications();
  Bloc.observer = di.sl<AppBlocObserver>();
}

void main() {
  // Hàm main chỉ còn nhiệm vụ chạy app, rất gọn gàng
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiBlocProvider vẫn giữ nguyên để cung cấp các BLoC toàn cục
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
        // ‼️ THAY ĐỔI QUAN TRỌNG: Trang đầu tiên là SplashScreen
        home: const SplashScreen(),
      ),
    );
  }
}

// =================================================================
//          WIDGET MỚI: MÀN HÌNH CHỜ (SPLASH SCREEN)
// =================================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Thực hiện tất cả các tác vụ khởi tạo nặng ở đây
    await _initializeApp();

    // Sau khi xong, điều hướng đến màn hình điều khiển chính
    // và xóa màn hình chờ khỏi cây widget (không thể quay lại)
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const InitialScreenController()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Giao diện của màn hình chờ
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: Bạn có thể đặt logo của mình ở đây
            // Image.asset('assets/logo.png', width: 150),
            // SizedBox(height: 24),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang khởi tạo...'),
          ],
        ),
      ),
    );
  }
}


// =================================================================
//        WIDGET ĐIỀU KHIỂN TRANG BAN ĐẦU (GIỮ NGUYÊN)
// =================================================================
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
        // Trạng thái loading của AuthBloc, sau khi splash screen đã chạy xong
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}