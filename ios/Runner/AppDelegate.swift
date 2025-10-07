// ios/Runner/AppDelegate.swift

import UIKit
import Flutter
import Firebase
import FBSDKCoreKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        // --- BẮT ĐẦU SỬA LỖI ---
        // Yêu cầu hệ điều hành cho phép nhận thông báo
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }
        application.registerForRemoteNotifications()
        // --- KẾT THÚC SỬA LỖI ---

        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // --- PHẦN NÀY ĐÃ CÓ VÀ ĐÚNG, GIỮ NGUYÊN ---
    override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    // --- PHẦN NÀY ĐÃ CÓ VÀ ĐÚNG, GIỮ NGUYÊN ---
    override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
        super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
}