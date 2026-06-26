import SwiftUI

/// The menu bar popover. Simple by default: the power button, a status line,
/// and a duration picker. Advanced settings live behind an inline disclosure.
struct MenuView: View {
    @EnvironmentObject var controller: ActivityController
    @State private var showAdvanced = false

    private var look: PowerButton.Look {
        if !controller.isTrusted { return .setup }
        return controller.isActive ? .active : .paused
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if controller.isTrusted {
                grantedBody
            } else {
                permissionGate
            }

            Divider().padding(.vertical, 4)

            HStack {
                if controller.isTrusted {
                    Button(showAdvanced ? "Advanced ▴" : "Advanced ▾") {
                        withAnimation(.easeInOut(duration: 0.15)) { showAdvanced.toggle() }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                } else {
                    Button("Why this permission?") { controller.requestPermission() }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .keyboardShortcut("q")
            }
            .font(.system(size: 12.5))
            .padding(.horizontal, 4)
        }
        .padding(12)
        .frame(width: 264)
    }

    // MARK: pieces

    private var header: some View {
        HStack {
            Text("stayup").font(.system(size: 13, weight: .semibold))
            Spacer()
        }
        .padding(.horizontal, 2)
        .padding(.bottom, 4)
    }

    private var grantedBody: some View {
        VStack(spacing: 6) {
            PowerButton(look: look) { controller.toggle() }
                .padding(.top, 6)

            Text(controller.isActive ? "Active" : "Paused")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(controller.isActive ? .primary : .secondary)

            statusLine
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .monospacedDigit()

            HStack {
                Text("Keep active for").foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: $controller.duration) {
                    ForEach(ActivityController.Duration.allCases) { d in
                        Text(d.label).tag(d)
                    }
                }
                .labelsHidden()
                .fixedSize()
            }
            .font(.system(size: 12.5))
            .padding(.top, 6)

            if showAdvanced {
                AdvancedView().transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private var statusLine: some View {
        if !controller.isActive {
            Text("You'll show as Away when idle")
        } else if let remaining = controller.timedRemaining {
            Text("Active for \(timeString(Int(remaining)))")
        } else {
            Text("Idle \(timeString(controller.idleSeconds)) · nudging in \(timeString(controller.secondsUntilNudge))")
        }
    }

    private var permissionGate: some View {
        VStack(spacing: 10) {
            PowerButton(look: .setup) { controller.requestPermission() }
                .padding(.top, 6)
            Text("Setup needed")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.orange)
            Text("stayup nudges the cursor a pixel when you're idle, so apps like Teams don't mark you Away while you're still working. It never reads or sets your status.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
            Button("Grant Accessibility Access…") { controller.requestPermission() }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
