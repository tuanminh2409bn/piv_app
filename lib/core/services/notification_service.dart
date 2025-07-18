// lib/core/services/notification_service.dart

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:piv_app/firebase_options.dart';

// SỬA: Import các trang đích và file main.dart
import 'package:piv_app/main.dart'; // Để dùng navigatorKey
import 'package:piv_app/features/orders/presentation/pages/order_detail_page.dart';
import 'package:piv_app/features/news/presentation/pages/news_detail_page.dart'; // Giả sử bạn có trang này
import 'package:piv_app/features/main/presentation/pages/main_screen.dart';     // Trang chủ sau khi đăng nhập

// --- Hàm xử lý nền ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  developer.log("Handling a background message: ${message.messageId}", name: "NotificationService");
  // Ở chế độ nền, Firebase tự hiển thị thông báo.
  // Nếu bạn muốn tùy chỉnh, bạn cần gọi local notification ở đây.
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'Thông báo Quan trọng',
    description: 'Kênh này được sử dụng cho các thông báo quan trọng.',
    importance: Importance.high,
  );

  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  Future<void> init() async {
    await _requestPermission();
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
    await _initLocalNotifications();
    _setupListeners();
    developer.log("✅ Notification Service Initialized Successfully", name: "NotificationService");
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@drawable/ic_notification');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      // SỬA: Xử lý khi người dùng nhấn vào thông báo (khi app đang MỞ hoặc chạy NỀN)
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        developer.log('User tapped notification. Payload: ${response.payload}', name: 'NotificationService');
        if (response.payload != null && response.payload!.isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(response.payload!);
          _handleNotificationNavigation(data); // Gọi hàm điều hướng tập trung
        }
      },
    );
  }

  Future<void> _requestPermission() async => _fcm.requestPermission();

  void _setupListeners() {
    // 1. Khi nhận được thông báo lúc app đang MỞ
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('Got a message whilst in the foreground!: ${message.data}', name: "NotificationService");
      final String? title = message.data['title'];
      final String? body = message.data['body'];
      if (title != null && body != null) {
        _showLocalNotification(title, body, message.data);
      }
    });

    // 2. Khi người dùng nhấn vào thông báo từ thanh trạng thái (khi app đang chạy NỀN)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('A new onMessageOpenedApp event was published! Data: ${message.data}', name: "NotificationService");
      _handleNotificationNavigation(message.data);
    });

    // 3. Khi app bị TẮT hoàn toàn, kiểm tra xem nó có được mở từ một thông báo không
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        developer.log('App opened from a terminated state by a notification! Data: ${message.data}', name: "NotificationService");
        // Thêm một chút delay để đảm bảo Navigator đã sẵn sàng
        Future.delayed(const Duration(seconds: 1), () {
          _handleNotificationNavigation(message.data);
        });
      }
    });
  }

  // SỬA: Hàm hiển thị thông báo cục bộ, giờ sẽ đính kèm TOÀN BỘ dữ liệu vào payload
  Future<void> _showLocalNotification(String title, String body, Map<String, dynamic> data) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channel.id, _channel.name, channelDescription: _channel.description,
      importance: Importance.max, priority: Priority.high, icon: '@drawable/ic_notification',
    );
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(presentSound: true, presentBadge: true, presentAlert: true),
    );

    await _localNotifications.show(
      Random().nextInt(100000), title, body, notificationDetails,
      payload: jsonEncode(data), // Mã hóa toàn bộ map data thành chuỗi JSON
    );
  }

  // SỬA: Hàm điều hướng tập trung, "bộ não" của hệ thống deep link
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final String? type = data['type'];
    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      developer.log("NavigatorKey is null, cannot navigate.", name: "NotificationService");
      return;
    }

    switch (type) {
      case 'new_article':
        final articleId = data['articleId'];
        if (articleId != null) {
          developer.log('Navigate to NewsDetailPage with ID: $articleId', name: "NotificationService");
          navigator.push(MaterialPageRoute(builder: (_) => NewsDetailPage(articleId: articleId)));
        }
        break;

      case 'order_status':
      case 'order_status_update_for_admin':
      case 'order_status_update_for_rep':
      case 'new_order_for_rep': // Thêm các type liên quan đến đơn hàng
        final orderId = data['orderId'];
        if (orderId != null) {
          developer.log('Navigate to OrderDetails screen with ID: $orderId', name: "NotificationService");
          navigator.push(OrderDetailPage.route(orderId));
        }
        break;

      case 'new_product':
        final productId = data['productId'];
        if(productId != null){
          developer.log('Navigate to ProductDetails screen with ID: $productId', name: "NotificationService");
          // navigator.push(ProductDetailPage.route(productId)); // Giả sử bạn có trang này
        }
        break;

      default:
        developer.log('Received notification with unknown type or no ID: $type', name: "NotificationService");
        navigator.push(MaterialPageRoute(builder: (_) => const MainScreen()));
        break;
    }
  }

  Future<void> saveTokenForUser(String userId) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await sl<UserProfileRepository>().updateUserProfilePartial(userId, {'fcmToken': token});
        developer.log("Saved FCM Token for user: $userId", name: "NotificationService");
      }
    } catch (e) {
      developer.log("Error saving FCM Token: $e", name: "NotificationService");
    }
  }

  Future<void> removeTokenForUser(String userId) async {
    try {
      await sl<UserProfileRepository>().updateUserProfilePartial(userId, {'fcmToken': null});
      developer.log("Removed FCM Token for user: $userId", name: "NotificationService");
    } catch (e) {
      developer.log("Error removing FCM Token: $e", name: "NotificationService");
    }
  }
}