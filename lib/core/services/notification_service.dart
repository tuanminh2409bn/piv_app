import 'dart:convert'; // SỬA: Thêm thư viện để làm việc với JSON
import 'dart:developer' as developer;
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:piv_app/firebase_options.dart';

// SỬA: Tạo một thể hiện (instance) của NotificationService để dùng trong hàm background
// Điều này đảm bảo chúng ta có thể gọi hàm _showLocalNotification từ bên ngoài class
final NotificationService _notificationService = NotificationService();

// Hàm xử lý thông báo nền, phải là một top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  developer.log("Handling a background message: ${message.messageId}", name: "NotificationService");

  // SỬA: Hiển thị thông báo khi nhận được ở chế độ nền/tắt
  final String? title = message.data['title'];
  final String? body = message.data['body'];
  if (title != null && body != null) {
    // Chúng ta không thể truy cập trực tiếp vào _localNotifications từ đây,
    // nên cần một mẹo nhỏ là gọi qua một instance được tạo ở top-level.
    // Đầu tiên cần khởi tạo nó.
    await _notificationService._initLocalNotifications();
    _notificationService._showLocalNotification(title, body, message.data);
  }
}


class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'Thông báo Quan trọng', // title
    description: 'Kênh này được sử dụng cho các thông báo quan trọng.',
    importance: Importance.high,
  );

  // SỬA: Constructor được đặt tên riêng để tránh xung đột với instance top-level
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
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@drawable/ic_notification');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        developer.log('User tapped notification. Payload: ${response.payload}', name: 'NotificationService');
        if (response.payload != null && response.payload!.isNotEmpty) {
          // SỬA: Giải mã payload từ JSON thành một Map
          final Map<String, dynamic> data = jsonDecode(response.payload!);
          final String? type = data['type'];

          // TODO: Xử lý điều hướng dựa trên 'type' và dữ liệu đi kèm
          // Ví dụ:
          if (type == 'order_status' || type == 'new_order_for_rep') {
            final orderId = data['orderId'];
            developer.log('Navigate to OrderDetails screen with ID: $orderId');
            // navigatorKey.currentState?.pushNamed('/order-details', arguments: orderId);
          } else if (type == 'new_product') {
            final productId = data['productId'];
            developer.log('Navigate to ProductDetails screen with ID: $productId');
            // navigatorKey.currentState?.pushNamed('/product-details', arguments: productId);
          } else if (type == 'account_approved') {
            developer.log('Navigate to Home screen');
            // navigatorKey.currentState?.pushNamed('/home');
          }
        }
      },
    );
  }

  Future<void> _requestPermission() async {
    await _fcm.requestPermission();
  }

  void _setupListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('Got a message whilst in the foreground!: ${message.data}', name: "NotificationService");
      final String? title = message.data['title'];
      final String? body = message.data['body'];
      if (title != null && body != null) {
        _showLocalNotification(title, body, message.data);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('A new onMessageOpenedApp event was published! Data: ${message.data}', name: "NotificationService");
      // SỬA: Khi người dùng nhấn vào thông báo từ trạng thái terminated,
      // chúng ta cũng cần điều hướng. Logic tương tự như onDidReceiveNotificationResponse.
      final String? type = message.data['type'];
      if (type != null) {
        // TODO: Thêm logic điều hướng tại đây
        developer.log('Tapped on notification from terminated state. Type: $type');
      }
    });

    // Quan trọng: Đăng ký hàm xử lý nền
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _showLocalNotification(String title, String body, Map<String, dynamic> data) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
    );
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(presentSound: true, presentBadge: true, presentAlert: true),
    );

    await _localNotifications.show(
      Random().nextInt(100000), // ID ngẫu nhiên
      title,
      body,
      notificationDetails,
      // SỬA: Chuyển toàn bộ dữ liệu (data) thành một chuỗi JSON.
      // Điều này giúp chúng ta có đầy đủ thông tin khi người dùng nhấn vào thông báo.
      payload: jsonEncode(data),
    );
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