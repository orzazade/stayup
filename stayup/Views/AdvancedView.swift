import SwiftUI

/// Inline Advanced disclosure — grouped Presence / Schedule / Behavior / General.
/// Stays compact so the expanded popover doesn't feel cramped. Settings are
/// stored via @AppStorage; the controller reads the same keys live at tick time.
struct AdvancedView: View {
    @EnvironmentObject var controller: ActivityController
    @EnvironmentObject var launchAtLogin: LaunchAtLoginManager

    @AppStorage("idleThreshold") private var idleThreshold: Int = 240
    @AppStorage("scheduleEnabled") private var scheduleEnabled: Bool = false
    @AppStorage("scheduleStartHour") private var scheduleStartHour: Int = 9
    @AppStorage("scheduleEndHour") private var scheduleEndHour: Int = 18
    @AppStorage("scheduleWeekdaysOnly") private var scheduleWeekdaysOnly: Bool = true

    private let rowFont = Font.system(size: 12.5)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Separates the Advanced area from the simple controls above.
            Divider().padding(.bottom, 2)

            // MARK: Presence
            group("Presence")
            HStack(spacing: 7) {
                Circle()
                    .fill(PresenceDetector.teamsRunning || PresenceDetector.slackRunning
                          ? Color.green : Color.secondary.opacity(0.4))
                    .frame(width: 7, height: 7)
                Text(presenceLabel).foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }

            // MARK: Schedule
            group("Schedule")
            toggleRow("Only during work hours", $scheduleEnabled.animation(.easeInOut(duration: 0.15)))
            if scheduleEnabled {
                HStack {
                    Text("Active hours").foregroundStyle(.secondary)
                    Spacer()
                    Stepper("\(twoDigit(scheduleStartHour)):00", value: $scheduleStartHour, in: 0...23)
                        .fixedSize()
                    Text("–").foregroundStyle(.tertiary)
                    Stepper("\(twoDigit(scheduleEndHour)):00", value: $scheduleEndHour, in: 0...23)
                        .fixedSize()
                }
                .monospacedDigit()
                .controlSize(.small)
                toggleRow("Weekdays only", $scheduleWeekdaysOnly)
            }

            // MARK: Behavior
            group("Behavior")
            HStack {
                Text("Nudge after idle").foregroundStyle(.secondary)
                Spacer()
                Text(thresholdLabel).monospacedDigit()
            }
            Slider(
                value: Binding(
                    get: { Double(idleThreshold) },
                    set: { idleThreshold = Int($0) }
                ),
                in: 30...600, step: 30
            )
            .controlSize(.small)
            .accessibilityLabel("Nudge after idle")
            .accessibilityValue(thresholdLabel)
            HStack {
                Text("30s").foregroundStyle(.tertiary)
                Spacer()
                Text("10 min").foregroundStyle(.tertiary)
            }
            .font(.system(size: 9.5))

            // MARK: General
            group("General")
            toggleRow("Launch at login", $launchAtLogin.isEnabled)
        }
        .font(rowFont)
    }

    /// A row with a leading label and a trailing mini switch, pinned flush-right
    /// to the same column as the other controls and centered against the label.
    private func toggleRow(_ title: String, _ isOn: Binding<Bool>) -> some View {
        HStack(spacing: 8) {
            Text(title)
            Spacer(minLength: 0)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.mini)
                .tint(.green)
        }
    }

    private var thresholdLabel: String {
        idleThreshold < 60 ? "\(idleThreshold)s" : "\(idleThreshold / 60) min"
    }

    private func twoDigit(_ h: Int) -> String { String(format: "%02d", h) }

    private var presenceLabel: String {
        switch (PresenceDetector.teamsRunning, PresenceDetector.slackRunning) {
        case (true, true):  return "Teams & Slack: running · kept active"
        case (true, false): return "Teams: running · kept active"
        case (false, true): return "Slack: running · kept active"
        case (false, false): return "Teams / Slack not running"
        }
    }

    private func group(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10.5, weight: .semibold))
            .tracking(0.5)
            .foregroundStyle(.tertiary)
            .padding(.top, 8)
    }
}
