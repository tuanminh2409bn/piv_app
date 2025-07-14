import 'dart:developer' as developer;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log("Handling a background message: ${message.messageId}", name: "NotificationService");
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final UserProfileRepository _userProfileRepository;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  NotificationService({required UserProfileRepository userProfileRepository})
      : _userProfileRepository = userProfileRepository;

  Future<void> initNotifications() async {
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
    developer.log("Notification Service Initialized", name: "NotificationService");
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@drawable/ic_notification');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        developer.log('notification payload: ${response.payload}', name: 'NotificationService');
      },
    );
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
      developer.log('A new onMessageOpenedApp event was published!', name: "NotificationService");
    });

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
      DateTime.now().millisecondsSinceEpoch.toSigned(53),
      title,
      body,
      notificationDetails,
      payload: data['orderId'],
    );
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      developer.log('User granted permission', name: "NotificationService");
    } else {
      developer.log('User declined or has not accepted permission', name: "NotificationService");
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