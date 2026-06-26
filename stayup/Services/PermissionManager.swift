import ApplicationServices
import AppKit

/// Accessibility (TCC) permission helpers. stayup needs this grant to post
/// synthetic events. The grant cannot be triggered by a one-tap API prompt —
/// the user must toggle it in System Settings, so we deep-link there.
enum PermissionManager {
    /// True when the app is trusted to control the computer (Accessibility on).
    static func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    /// Open System Settings → Privacy & Security → Accessibility.
    @MainActor
    static func openAccessibilitySettings() {
        guard let url = URL(string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        else { return }
        NSWorkspace.shared.open(url)
    }
}
