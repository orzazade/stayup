import Foundation
import UserNotifications

/// Local notifications. Used to tell the user when a timed session ends, so a
/// "keep me active for this one meeting" session never drops silently.
actor NotificationService {
    static let shared = NotificationService()

    private var permissionGranted = false

    func requestPermission() async -> Bool {
        do {
            permissionGranted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            return permissionGranted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    func notifySessionEnded() async {
        guard permissionGranted else { return }

        let content = UNMutableNotificationContent()
        content.title = "stayup session ended"
        content.body = "You'll now show as Away when idle."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }
}
