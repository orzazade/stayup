import Foundation
import CoreGraphics

/// Reads how long the user has been idle, measured the same way Electron apps
/// (Teams, Slack) measure it: seconds since the last input event on the combined
/// session state. We take the minimum across the input event types, which is
/// effectively "seconds since any input" — the value that flips you to Away.
enum IdleMonitor {
    private static let inputTypes: [CGEventType] = [
        .mouseMoved,
        .leftMouseDown,
        .rightMouseDown,
        .otherMouseDown,
        .leftMouseDragged,
        .rightMouseDragged,
        .keyDown,
        .scrollWheel,
        .flagsChanged
    ]

    /// Seconds since the most recent user input of any kind.
    static func idleSeconds() -> TimeInterval {
        inputTypes
            .map { CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0) }
            .min() ?? 0
    }
}
