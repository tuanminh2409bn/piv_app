//lib/core/services/notification_service.dart

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'dart:io'; 

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/news/presentation/pages/news_detail_page.dart';
import 'package:piv_app/features/notifications/presentation/pages/notification_list_page.dart';
import 'package:piv_app/features/orders/presentation/pages/order_detail_page.dart';
import 'package:piv_app/features/products/presentation/pages/product_detail_page.dart';
import 'package:piv_app/features/returns/presentation/pages/admin_return_request_loader_page.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_debt_approval_page.dart';
import 'package:piv_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:piv_app/features/sales_commitment/presentation/pages/admin_commitments_page.dart';
import 'package:piv_app/features/sales_commitment/presentation/pages/sales_commitment_page.dart';
import 'package:piv_app/features/sales_commitment/presentation/pages/commitment_history_page.dart';
import 'package:piv_app/firebase_options.dart';
import 'package:piv_app/main.dart';

final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'Thông báo PIV',
  description: 'Kênh nhận các thông báo quan trọng từ PIV.',
  importance: Importance.max,
);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  developer.log("🔥 [BACKGROUND] Nhận thông báo nền: ${message.notification?.title}", name: "NotificationService");
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool _isInitialized = false;

  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }
    developer.log("🚀 Bắt đầu khởi tạo Notification Service...", name: "NotificationService");

    await _requestPermission();
    await _configureForegroundOptions();
    await _createAndroidChannel();
    await _initLocalNotifications();
    _setupListeners();

    _isInitialized = true;
    developer.log("✅ Khởi tạo Notification Service thành công!", name: "NotificationService");
  }

  Future<void> _requestPermission() async {
    developer.log("🔐 Đang xin quyền nhận thông báo...", name: "NotificationService");
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> _configureForegroundOptions() async {
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _createAndroidChannel() async {
    if (!kIsWeb && Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
      developer.log("📡 Đã tạo kênh '${_androidChannel.id}' cho Android.", name: "NotificationService");
    }
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@drawable/ic_notification');
    
    // Bỏ const để tránh lỗi trên một số phiên bản Dart cũ hơn hoặc cấu hình strict
    final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            _handleNotificationNavigation(data);
          } catch (e) {
            developer.log("Lỗi parse payload từ local notification: $e", name: "NotificationService");
          }
        }
      },
    );
  }

  void _setupListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('🟢 [FOREGROUND] Nhận được thông báo: ${message.notification?.title}', name: "NotificationService");
      final RemoteNotification? notification = message.notification;

      // Chỉ hiển thị Local Notification trên Android
      // iOS tự động hiển thị khi app ở foreground nếu đã cấu hình presentation options (đã làm ở trên)
      if (notification != null && !kIsWeb && Platform.isAndroid) {
        _showLocalNotification(
          notification.title ?? 'Thông báo',
          notification.body ?? '',
          message.data,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('🔵 [BACKGROUND TAP] Mở app từ thông báo: ${message.data}', name: "NotificationService");
      _handleNotificationNavigation(message.data);
    });

    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        developer.log('🔴 [TERMINATED TAP] Mở app từ thông báo: ${message.data}', name: "NotificationService");
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNotificationNavigation(message.data);
        });
      }
    });
  }

  Future<void> _showLocalNotification(String title, String body, Map<String, dynamic> data) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
    );

    // Bỏ const ở đây
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(presentSound: true, presentBadge: true, presentAlert: true),
    );

    await _localNotifications.show(
      id: Random().nextInt(100000),
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: jsonEncode(data),
    );
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final String? type = data['type'];
    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      developer.log("NavigatorKey is null, không thể điều hướng.", name: "NotificationService");
      return;
    }
    developer.log("Điều hướng cho loại thông báo: '$type' với data: $data", name: "NotificationService");

    switch (type) {
      case 'new_article':
        final articleId = data['articleId'];
        if (articleId != null) {
          navigator.push(NewsDetailPage.route(articleId));
        }
        break;
      case 'new_product':
        final productId = data['productId'];
        if (productId != null) {
          navigator.push(ProductDetailPage.route(productId));
        }
        break;
      case 'order_status':
      case 'order_status_general':
      case 'new_order_for_rep':
      case 'new_order_for_admin':
      case 'order_approval_request':
      case 'order_approval_result':
        final orderId = data['orderId'];
        if (orderId != null) {
          navigator.push(OrderDetailPage.route(orderId));
        }
        break;
      case 'account_approved':
      case 'account_management':
        navigator.push(NotificationListPage.route());
        break;
      case 'new_return_request':
      case 'return_request_status_update':
      case 'return_request_approved_for_accountant':
        final returnRequestId = data['returnRequestId'];
        if (returnRequestId != null) {
          navigator.push(AdminReturnRequestLoaderPage.route(returnRequestId));
        } else {
           developer.log("Thiếu returnRequestId trong payload.", name: "NotificationService");
        }
        break;
      case 'commitment_approval_request':
        final commitmentId = data['commitmentId'];
        navigator.push(AdminCommitmentsPage.route(commitmentId: commitmentId));
        break;
      case 'commitment_approved':
      case 'commitment_created':
      case 'commitment_details_set':
        navigator.push(MaterialPageRoute(builder: (_) => const SalesCommitmentPage()));
        break;
      case 'commitment_cancelled':
      case 'commitment_expired':
      case 'commitment_completed':
        final commitmentId = data['commitmentId'];
        navigator.push(CommitmentHistoryPage.route(commitmentId: commitmentId));
        break;
      case 'debt_update_request':
      case 'debt_update_response':
        navigator.push(AdminDebtApprovalPage.route());
        break;
      default:
        developer.log('Loại thông báo không xác định: $type. Mở trang thông báo.', name: "NotificationService");
        navigator.push(NotificationListPage.route());
        break;
    }
  }

  Future<void> saveTokenForUser(String userId) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await sl<UserProfileRepository>().updateUserProfilePartial(userId, {'fcmToken': token});
        developer.log("Đã lưu FCM Token cho user: $userId", name: "NotificationService");
      }
    } catch (e) {
      developer.log("Lỗi khi lưu FCM Token: $e", name: "NotificationService");
    }
  }

  Future<void> removeTokenForUser(String userId) async {
    try {
      await sl<UserProfileRepository>().updateUserProfilePartial(userId, {'fcmToken': FieldValue.delete()});
      developer.log("Đã xóa FCM Token cho user: $userId", name: "NotificationService");
    } catch (e) {
      developer.log("Lỗi khi xóa FCM Token: $e", name: "NotificationService");
    }
  }
}
