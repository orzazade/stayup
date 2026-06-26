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

            Divider().padding(.top, 12).padding(.bottom, 7)

            HStack {
                if controller.isTrusted {
                    Button(showAdvanced ? "Advanced ▴" : "Advanced ▾") {
                        showAdvanced.toggle()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                } else {
                    Button("Why this?") { controller.requestPermission() }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    HStack(spacing: 5) {
                        Text("Quit").foregroundStyle(.secondary)
                        Text("⌘Q").foregroundStyle(.tertiary).font(.system(size: 11))
                    }
                }
                .buttonStyle(.plain)
                .keyboardShortcut("q")
            }
            .font(.system(size: 12.5))
            .padding(.horizontal, 4)
            .padding(.bottom, 2)
        }
        .padding(14)
        .frame(width: 264)
    }

    // MARK: pieces

    private var header: some View {
        HStack {
            Text("stayup").font(.system(size: 13, weight: .semibold))
            Spacer()
            if controller.isTrusted {
                Button {
                    showAdvanced.toggle()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 2)
        .padding(.bottom, 6)
    }

    private var grantedBody: some View {
        VStack(spacing: 6) {
            PowerButton(look: look) { controller.toggle() }
                .padding(.top, 2)

            Text(controller.isActive ? "Active" : "Paused")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(controller.isActive ? .primary : .secondary)
                .padding(.top, 4)

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
                AdvancedView()
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
        VStack(spacing: 0) {
            PowerButton(look: .setup) { controller.requestPermission() }
                .padding(.top, 2)
            Text("Setup needed")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.orange)
                .padding(.top, 4)
            Text("stayup nudges the cursor a pixel when you're idle, so apps like Teams don't mark you Away while you're still working. It never reads or sets your status.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 6)
                .padding(.top, 10)
            Button {
                controller.requestPermission()
            } label: {
                Text("Grant Accessibility Access…")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
        }
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
