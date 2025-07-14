import 'dart:developer' as developer;
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:piv_app/firebase_options.dart';

// Hàm xử lý thông báo nền, phải là một top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Khởi tạo Firebase để các plugin khác có thể hoạt động ở chế độ nền.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  developer.log("Handling a background message: ${message.messageId}", name: "NotificationService");
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Định nghĩa một Kênh Thông báo với độ ưu tiên cao cho Android.
  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'Thông báo Quan trọng', // title
    description: 'Kênh này được sử dụng cho các thông báo quan trọng.',
    importance: Importance.high,
  );

  NotificationService();

  /// Khởi tạo toàn bộ dịch vụ thông báo.
  Future<void> init() async {
    // 1. Xin quyền từ người dùng (iOS & Android 13+).
    await _requestPermission();

    // 2. Yêu cầu FCM hiển thị thông báo khi app đang mở (quan trọng cho iOS).
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Tạo Kênh Thông báo cho Android.
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 4. Cài đặt cho local notifications.
    await _initLocalNotifications();

    // 5. Lắng nghe các sự kiện thông báo.
    _setupListeners();
    developer.log("✅ Notification Service Initialized Successfully", name: "NotificationService");
  }

  /// Khởi tạo cài đặt cho flutter_local_notifications.
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
        developer.log('notification payload: ${response.payload}', name: 'NotificationService');
        // TODO: Xử lý điều hướng khi người dùng nhấn vào thông báo
      },
    );
  }

  /// Xin quyền nhận thông báo từ người dùng.
  Future<void> _requestPermission() async {
    await _fcm.requestPermission();
  }

  /// Lắng nghe các luồng thông báo từ Firebase.
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
      developer.log('A new onMessageOpenedApp event was published!', name: "NotificationService");
      // TODO: Điều hướng đến màn hình tương ứng dựa vào dữ liệu của thông báo
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Hiển thị một thông báo cục bộ khi ứng dụng đang mở.
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

    // Sử dụng một số nguyên ngẫu nhiên, an toàn để tránh lỗi ID
    await _localNotifications.show(
      Random().nextInt(100000),
      title,
      body,
      notificationDetails,
      payload: data['orderId'] as String?,
    );
  }

  /// Lấy và lưu token vào Firestore cho người dùng.
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

  /// Xóa token khỏi Firestore khi người dùng đăng xuất.
  Future<void> removeTokenForUser(String userId) async {
    try {
      await sl<UserProfileRepository>().updateUserProfilePartial(userId, {'fcmToken': null});
      developer.log("Removed FCM Token for user: $userId", name: "NotificationService");
    } catch (e) {
      developer.log("Error removing FCM Token: $e", name: "NotificationService");
    }
  }
}