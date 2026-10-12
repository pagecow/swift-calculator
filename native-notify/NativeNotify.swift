// Native Notify — device registration (added by Agent Notify).
//
// Add this file to your app target (Xcode: File -> Add Files…), then call
// NativeNotify.register(...) from
// application(_:didRegisterForRemoteNotificationsWithDeviceToken:).
//
// Values come from your configuration (an xcconfig / Info.plist key) —
// never commit them:
//   NN_APP_ID, NN_APP_TOKEN

import Foundation

enum NativeNotify {
    static let registerURL = URL(string: "https://app.nativenotify.com/api/universal/device/register")!
    static let deregisterURL = URL(string: "https://app.nativenotify.com/api/universal/device/deregister")!

    static var appId: Int? { Int(Bundle.main.object(forInfoDictionaryKey: "NN_APP_ID") as? String ?? "") }
    static var appToken: String? { Bundle.main.object(forInfoDictionaryKey: "NN_APP_TOKEN") as? String }

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
                userInfo: [NSLocalizedDescriptionKey: "NN_APP_ID / NN_APP_TOKEN missing from Info.plist"])))
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
