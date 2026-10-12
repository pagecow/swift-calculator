//
//  SwiftCalculatorApp.swift
//  SwiftCalculator
//
//  The entry point. `@main` marks the type Xcode launches when the app starts.
//

import SwiftUI
import UIKit
import UserNotifications

@main
struct SwiftCalculatorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// Asks for notification permission, then registers this device with Native
/// Notify — see native-notify/NativeNotify.swift.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async { application.registerForRemoteNotifications() }
        }
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        NativeNotify.register(deviceId: NativeNotify.deviceId, apnsToken: hex) { result in
            switch result {
            case .success(let response):
                print("Native Notify: device registered \(response)")
            case .failure(let error):
                print("Native Notify: registration failed — \(error.localizedDescription)")
            }
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Native Notify: APNs registration failed — \(error.localizedDescription)")
    }

    /// Shows the banner even while the app is open — handy for the first test push.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
