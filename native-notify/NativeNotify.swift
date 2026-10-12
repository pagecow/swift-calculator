// Native Notify — device registration (added by Agent Notify).
//
// Add this file to your app target once: in Xcode choose
// File -> Add Files to "SwiftCalculator"… and pick native-notify/NativeNotify.swift.
//
// The app id is already filled in below. Paste your app token into
// NativeNotifyConfig.appToken — dashboard -> Keys (left sidebar) has a Copy
// button next to it. The token can send notifications to your users, so keep
// this repository private.

import Foundation

// ── Paste your app token here ────────────────────────────────────────────────
enum NativeNotifyConfig {
    /// Your Native Notify app id (already filled in for Swift Calculator).
    static let appId: Int = 33957
    /// Replace the text between the quotes with your app token.
    static let appToken: String = "PASTE_YOUR_APP_TOKEN_HERE"
}

enum NativeNotify {
    static let registerURL = URL(string: "https://app.nativenotify.com/api/universal/device/register")!
    static let deregisterURL = URL(string: "https://app.nativenotify.com/api/universal/device/deregister")!

    static var appId: Int? { NativeNotifyConfig.appId == 0 ? nil : NativeNotifyConfig.appId }
    static var appToken: String? {
        let token = NativeNotifyConfig.appToken
        return (token.isEmpty || token.hasPrefix("PASTE")) ? nil : token
    }

    /// A stable id for this install, used to register and later refresh the device.
    static var deviceId: String {
        let key = "nn_device_id"
        if let existing = UserDefaults.standard.string(forKey: key) { return existing }
        let fresh = UUID().uuidString
        UserDefaults.standard.set(fresh, forKey: key)
        return fresh
    }

    /// Register (or refresh) this device. [apnsToken] is the hex string
    /// handed to didRegisterForRemoteNotificationsWithDeviceToken.
    static func register(
        deviceId: String,
        apnsToken: String,
        subscriberId: String? = nil,
        completion: @escaping (Result<[String: Any], Error>) -> Void
    ) {
        guard let appId, let appToken else {
            completion(.failure(NSError(domain: "NativeNotify", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Paste your app token into NativeNotifyConfig (native-notify/NativeNotify.swift)"])))
            return
        }
        var payload: [String: Any] = [
            "appId": appId,
            "appToken": appToken,
            "deviceId": deviceId,
            "platform": "ios",
            "tokens": ["apnsToken": apnsToken],
        ]
        if let subscriberId { payload["subscriberId"] = subscriberId }
        send(payload, to: registerURL, completion: completion)
    }

    /// Call on logout — the device stops receiving pushes.
    static func deregister(deviceId: String, completion: (([String: Any]) -> Void)? = nil) {
        guard let appId, let appToken else { return }
        send(["appId": appId, "appToken": appToken, "deviceId": deviceId], to: deregisterURL) { _ in }
        completion?([:])
    }

    private static func send(_ payload: [String: Any], to url: URL,
                             completion: @escaping (Result<[String: Any], Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error { completion(.failure(error)); return }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let json = (data.flatMap { try? JSONSerialization.jsonObject(with: $0) }) as? [String: Any] ?? [:]
            if status >= 300 {
                completion(.failure(NSError(domain: "NativeNotify", code: status,
                    userInfo: [NSLocalizedDescriptionKey: "registration failed: \(json)"])))
            } else {
                completion(.success(json))
            }
        }.resume()
    }
}
