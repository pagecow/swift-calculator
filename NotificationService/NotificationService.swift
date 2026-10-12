// Native Notify — notification service extension (added by Agent Notify).
//
// Shows the image of a push that carries one (the "Big picture" of a send, `bigPictureURL`
// in the API). iOS never downloads a remote image by itself: before the notification
// appears, this extension gets about 30 seconds to fetch it and attach it. A push without
// an image passes through untouched. Nothing here needs editing.

import UserNotifications

final class NotificationService: UNNotificationServiceExtension {
    private var delivery: Delivery?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        let content = (request.content.mutableCopy() as? UNMutableNotificationContent) ?? UNMutableNotificationContent()
        let delivery = Delivery(content: content, handler: contentHandler)
        self.delivery = delivery

        guard let url = NativeNotifyImage.url(in: request.content.userInfo) else {
            delivery.finish()
            return
        }
        var download = URLRequest(url: url)
        download.timeoutInterval = 20
        URLSession.shared.downloadTask(with: download) { location, response, _ in
            if let location = location, let attachment = NativeNotifyImage.attachment(from: location, response: response, url: url) {
                delivery.attach(attachment)
            }
            delivery.finish()
        }.resume()
    }

    override func serviceExtensionTimeWillExpire() {
        // Out of time: deliver the notification as it is.
        delivery?.finish()
    }
}

/// Hands the notification to iOS exactly once — when the download finishes or when time runs out, whichever comes first.
private final class Delivery: @unchecked Sendable {
    private let lock = NSLock()
    private let content: UNMutableNotificationContent
    private let handler: (UNNotificationContent) -> Void
    private var finished = false

    init(content: UNMutableNotificationContent, handler: @escaping (UNNotificationContent) -> Void) {
        self.content = content
        self.handler = handler
    }

    func attach(_ attachment: UNNotificationAttachment) {
        lock.lock()
        defer { lock.unlock() }
        if !finished { content.attachments = [attachment] }
    }

    func finish() {
        lock.lock()
        let alreadyFinished = finished
        finished = true
        lock.unlock()
        if !alreadyFinished { handler(content) }
    }
}

private enum NativeNotifyImage {
    /// The https image URL Native Notify puts in the push (`image`; Firebase's `fcm_options.image` is read too).
    static func url(in userInfo: [AnyHashable: Any]) -> URL? {
        var text = userInfo["image"] as? String
        if text == nil, let options = userInfo["fcm_options"] as? [String: Any] { text = options["image"] as? String }
        guard let value = text, let url = URL(string: value), url.scheme?.lowercased() == "https" else { return nil }
        return url
    }

    /// Attaches the downloaded file — only when the server really answered with a JPEG, PNG or GIF (an error page is never attached).
    static func attachment(from location: URL, response: URLResponse?, url: URL) -> UNNotificationAttachment? {
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) { return nil }
        guard let ext = fileExtension(mimeType: response?.mimeType, url: url) else { return nil }
        let name = "\(UUID().uuidString).\(ext)" // iOS reads the image type from the file extension
        let destination = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)
        do {
            try FileManager.default.moveItem(at: location, to: destination)
            return try UNNotificationAttachment(identifier: "native-notify-image", url: destination, options: nil)
        } catch {
            return nil
        }
    }

    /// png, jpg or gif — from what the server says the file is (the URL's own ending only when the server says nothing useful). nil for anything else.
    private static func fileExtension(mimeType: String?, url: URL) -> String? {
        switch mimeType?.lowercased() {
        case "image/png": return "png"
        case "image/gif": return "gif"
        case "image/jpeg", "image/jpg", "image/pjpeg": return "jpg"
        case nil, "application/octet-stream", "binary/octet-stream":
            let ext = url.pathExtension.lowercased()
            if ext == "jpeg" { return "jpg" }
            return ["png", "jpg", "gif"].contains(ext) ? ext : nil
        default: return nil
        }
    }
}
