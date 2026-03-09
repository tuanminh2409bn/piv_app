// lib/main.dart

import 'dart:io';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'firebase_options.dart';
import 'package:piv_app/app/app_bloc_observer.dart';
import 'package:piv_app/core/di/injection_container.dart' as di;
import 'package:piv_app/core/services/notification_service.dart';
import 'package:piv_app/core/theme/app_theme.dart';

import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/auth/presentation/pages/login_page.dart';
import 'package:piv_app/features/auth/presentation/pages/complete_profile_page.dart';
import 'package:piv_app/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:piv_app/features/main/presentation/pages/main_screen.dart';
import 'package:piv_app/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:piv_app/features/wishlist/presentation/bloc/wishlist_cubit.dart';
import 'package:piv_app/features/notifications/presentation/bloc/notification_cubit.dart';

import 'package:piv_app/features/admin/presentation/pages/admin_home_page.dart';
import 'package:piv_app/features/sales_rep/presentation/pages/sales_rep_home_page.dart';
import 'package:piv_app/features/accountant/presentation/pages/accountant_home_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  developer.log("Handling a background message: ${message.messageId}", name: "BackgroundNotification");
}

Future<void> _requestTrackingPermission() async {
  if (Platform.isIOS) {
    final status = await AppTrackingTransparency.requestTrackingAuthorization();
    developer.log('App Tracking Transparency status: $status', name: 'ATT');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- CẤU HÌNH SYSTEM UI (Thanh trạng thái & Thanh điều hướng trong suốt) ---
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    
    // Thêm phần này cho Android Edge-to-Edge:
    systemNavigationBarColor: Colors.transparent, 
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark, 
  ));
  
  // Bắt buộc kích hoạt chế độ Edge-to-Edge trên Android 10+
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // --------------------------------------------------------

  await _requestTrackingPermission();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await di.initializeDependencies();
  await di.sl<NotificationService>().init();
  await initializeDateFormatting('vi_VN', null);

  Bloc.observer = di.sl<AppBlocObserver>();
  timeago.setLocaleMessages('vi', timeago.ViMessages());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (context) => di.sl<AuthBloc>()..add(AuthAppStarted())),
        BlocProvider<CartCubit>(create: (context) => di.sl<CartCubit>()),
        BlocProvider<WishlistCubit>(create: (context) => di.sl<WishlistCubit>()),
        BlocProvider<ProfileCubit>(create: (context) => di.sl<ProfileCubit>()),
        BlocProvider<NotificationCubit>(create: (context) => di.sl<NotificationCubit>()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Phân Bón PIV',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
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
        builder: (context, child) {
          return GestureDetector(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: child,
          );
        },
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
          }
          else if (state.user.isAccountant) {
            return const AccountantHomePage();
          }
          else {
            return const MainScreen();
          }
        }
        if (state is AuthProfileIncomplete) {
          return CompleteProfilePage(user: state.user);
        }
        if (state is AuthUnauthenticated || state is AuthAccountPending) {
          return const LoginPage();
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
