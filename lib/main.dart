import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/app/app_bloc_observer.dart'; // Quan sát viên cho BLoC
import 'package:piv_app/core/di/injection_container.dart' as di; // Dependency Injection
import 'firebase_options.dart'; // Cấu hình Firebase được tạo tự động

// Import các thành phần của Auth feature
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
// Import HomePage
import 'package:piv_app/features/home/presentation/pages/home_page.dart';
// Import LoginPage
import 'package:piv_app/features/auth/presentation/pages/login_page.dart';


// Hàm main - điểm bắt đầu của ứng dụng
void main() async {
  // Đảm bảo Flutter bindings đã được khởi tạo
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Khởi tạo Dependency Injection (Service Locator)
  await di.initializeDependencies();

  // (Tùy chọn) Khởi tạo BlocObserver để theo dõi các sự kiện và trạng thái của BLoC
  Bloc.observer = AppBlocObserver();

  // Chạy ứng dụng
  runApp(const MyApp());
}

// Widget gốc của ứng dụng
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Cung cấp AuthBloc cho toàn bộ cây widget con
    // AuthBloc được lấy từ service locator (di.sl)
    // và sự kiện AuthAppStarted được gửi để kiểm tra trạng thái đăng nhập ban đầu
    return BlocProvider(
      create: (context) => di.sl<AuthBloc>()..add(AuthAppStarted()),
      child: MaterialApp(
        title: 'Phân Bón PIV',
        debugShowCheckedModeBanner: false, // Tắt banner "Debug" ở góc trên bên phải
        theme: ThemeData( // Định nghĩa theme chung cho ứng dụng
            primarySwatch: Colors.green, // Màu chủ đạo cơ bản
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green.shade700), // Bảng màu dựa trên màu gốc
            useMaterial3: true, // Sử dụng Material Design 3

            // Theme tùy chỉnh cho các TextFormField
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green.shade700, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),

            // Theme tùy chỉnh cho các ElevatedButton
            elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700, // Màu nền nút
                  foregroundColor: Colors.white, // Màu chữ/icon trên nút
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                )
            ),

            // Theme tùy chỉnh cho các TextButton
            textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                    foregroundColor: Colors.green.shade700, // Màu chữ
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)
                )
            )
        ),
        // Màn hình đầu tiên được hiển thị, quyết định dựa trên trạng thái xác thực
        home: const InitialScreenController(),
      ),
    );
  }
}

// Widget điều hướng màn hình ban đầu dựa trên trạng thái AuthBloc
class InitialScreenController extends StatelessWidget {
  const InitialScreenController({super.key});

  @override
  Widget build(BuildContext context) {
    // Sử dụng BlocBuilder để lắng nghe và rebuild UI dựa trên trạng thái của AuthBloc
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Trường hợp: Người dùng đã được xác thực (đăng nhập thành công)
        if (state is AuthAuthenticated) {
          // Điều hướng đến HomePage
          return const HomePage();
        }
        // Trường hợp: Người dùng chưa được xác thực (chưa đăng nhập hoặc đã đăng xuất)
        else if (state is AuthUnauthenticated) {
          // Điều hướng đến LoginPage
          return const LoginPage();
        }
        // Trường hợp: Trạng thái AuthInitial (khởi tạo) hoặc AuthLoading (đang xử lý)
        // Hiển thị một chỉ báo đang tải ở giữa màn hình
        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: Colors.green)),
        );
      },
    );
  }
}
