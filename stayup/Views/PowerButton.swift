import SwiftUI

/// The signature element: one big circular power button. Glowing green when
/// Active, dim grey when Paused, amber when setup is needed. Tapping toggles.
struct PowerButton: View {
    enum Look { case active, paused, setup }

    let look: Look
    let action: () -> Void

    private var fill: LinearGradient {
        switch look {
        case .active:
            return LinearGradient(colors: [Color(red: 0.23, green: 0.88, blue: 0.42),
                                           Color(red: 0.12, green: 0.62, blue: 0.26)],
                                  startPoint: .top, endPoint: .bottom)
        case .paused:
            return LinearGradient(colors: [Color(white: 0.34), Color(white: 0.22)],
                                  startPoint: .top, endPoint: .bottom)
        case .setup:
            return LinearGradient(colors: [Color(red: 1.0, green: 0.70, blue: 0.25),
                                           Color(red: 0.85, green: 0.49, blue: 0.0)],
                                  startPoint: .top, endPoint: .bottom)
        }
    }

    private var glow: Color {
        switch look {
        case .active: return Color(red: 0.23, green: 0.88, blue: 0.42).opacity(0.55)
        case .setup: return Color(red: 1.0, green: 0.62, blue: 0.04).opacity(0.45)
        case .paused: return .clear
        }
    }

    private var glyphColor: Color {
        switch look {
        case .active: return Color(red: 0.05, green: 0.22, blue: 0.10)
        case .paused: return Color(white: 0.55)
        case .setup: return Color(red: 0.22, green: 0.14, blue: 0.0)
        }
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(fill)
                    .overlay(Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1))
                    .shadow(color: glow, radius: look == .paused ? 0 : 18)
                Image(systemName: "power")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(glyphColor)
            }
            .frame(width: 116, height: 116)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel("stayup")
        .accessibilityValue(look == .active ? "Active" : look == .paused ? "Paused" : "Needs permission")
        .accessibilityHint("Toggles keeping you active")
    }
}
