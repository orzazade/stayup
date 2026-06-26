import AppKit

/// Detects whether Teams / Slack are *running* — nothing more. stayup never
/// reads or reports their real presence status (that needs the Graph/Slack API
/// and network, which this app deliberately never touches). The UI label says
/// "running · kept active", never "Available".
enum PresenceDetector {
    static let teamsBundleIDs = ["com.microsoft.teams", "com.microsoft.teams2"]
    static let slackBundleIDs = ["com.tinyspeck.slackmacgap"]

    static func isRunning(_ bundleIDs: [String]) -> Bool {
        let running = Set(
            NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier }
        )
        return bundleIDs.contains { running.contains($0) }
    }

    static var teamsRunning: Bool { isRunning(teamsBundleIDs) }
    static var slackRunning: Bool { isRunning(slackBundleIDs) }
}
