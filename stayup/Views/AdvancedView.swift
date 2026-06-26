import SwiftUI

/// Inline Advanced disclosure — grouped Presence / Schedule / Behavior. Stays
/// compact so the expanded popover doesn't feel cramped. Settings are stored
/// via @AppStorage; the controller reads the same keys live at tick time.
struct AdvancedView: View {
    @EnvironmentObject var controller: ActivityController
    @EnvironmentObject var launchAtLogin: LaunchAtLoginManager

    @AppStorage("idleThreshold") private var idleThreshold: Int = 240
    @AppStorage("scheduleEnabled") private var scheduleEnabled: Bool = false
    @AppStorage("scheduleStartHour") private var scheduleStartHour: Int = 9
    @AppStorage("scheduleEndHour") private var scheduleEndHour: Int = 18
    @AppStorage("scheduleWeekdaysOnly") private var scheduleWeekdaysOnly: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            group("Presence")
            HStack {
                Circle().fill(PresenceDetector.teamsRunning ? .green : Color.secondary.opacity(0.4))
                    .frame(width: 7, height: 7)
                Text(presenceLabel).foregroundStyle(.secondary)
            }
            .font(.system(size: 12))
            .padding(.vertical, 3)

            group("Schedule")
            Toggle("Only during work hours", isOn: $scheduleEnabled)
                .font(.system(size: 12.5))
            if scheduleEnabled {
                HStack {
                    Text("From").foregroundStyle(.secondary)
                    Stepper("\(scheduleStartHour):00", value: $scheduleStartHour, in: 0...23)
                    Text("to").foregroundStyle(.secondary)
                    Stepper("\(scheduleEndHour):00", value: $scheduleEndHour, in: 0...23)
                }
                .font(.system(size: 11.5))
                Toggle("Weekdays only", isOn: $scheduleWeekdaysOnly)
                    .font(.system(size: 12.5))
            }

            group("Behavior")
            HStack {
                Text("Nudge after idle").foregroundStyle(.secondary)
                Spacer()
                Text("\(idleThreshold / 60) min").monospacedDigit()
            }
            .font(.system(size: 12.5))
            Slider(value: Binding(
                get: { Double(idleThreshold) },
                set: { idleThreshold = Int($0) }
            ), in: 30...600, step: 30)

            Toggle("Launch at login", isOn: $launchAtLogin.isEnabled)
                .font(.system(size: 12.5))
        }
        .toggleStyle(.switch)
        .controlSize(.mini)
        .padding(.top, 6)
    }

    private var presenceLabel: String {
        switch (PresenceDetector.teamsRunning, PresenceDetector.slackRunning) {
        case (true, true): return "Teams & Slack: running · kept active"
        case (true, false): return "Teams: running · kept active"
        case (false, true): return "Slack: running · kept active"
        case (false, false): return "Teams / Slack not running"
        }
    }

    private func group(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.tertiary)
            .padding(.top, 8)
    }
}
