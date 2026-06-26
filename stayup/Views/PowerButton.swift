import SwiftUI

/// The signature element: one big circular power button, tuned to match the
/// design mockup — radial top-lit fill, an outer glow halo, a soft colored
/// ring, and an inner highlight. Glowing green = Active, dim grey = Paused,
/// amber = setup needed. Tapping toggles.
struct PowerButton: View {
    enum Look { case active, paused, setup }

    let look: Look
    let action: () -> Void

    private static let activeTop = Color(red: 0.23, green: 0.88, blue: 0.42)
    private static let activeBot = Color(red: 0.12, green: 0.62, blue: 0.26)
    private static let amberTop  = Color(red: 1.00, green: 0.70, blue: 0.25)
    private static let amberBot  = Color(red: 0.85, green: 0.49, blue: 0.00)
    private static let greyTop   = Color(white: 0.30)
    private static let greyBot   = Color(white: 0.17)

    private var top: Color {
        switch look { case .active: return Self.activeTop; case .setup: return Self.amberTop; case .paused: return Self.greyTop }
    }
    private var bottom: Color {
        switch look { case .active: return Self.activeBot; case .setup: return Self.amberBot; case .paused: return Self.greyBot }
    }
    private var glow: Color {
        switch look {
        case .active: return Color(red: 0.19, green: 0.82, blue: 0.35)
        case .setup:  return Color(red: 1.00, green: 0.62, blue: 0.04)
        case .paused: return .clear
        }
    }
    private var glyphColor: Color {
        switch look {
        case .active: return Color(red: 0.05, green: 0.22, blue: 0.10)
        case .setup:  return Color(red: 0.22, green: 0.14, blue: 0.00)
        case .paused: return Color(white: 0.55)
        }
    }

    private let size: CGFloat = 128

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer glow halo
                Circle()
                    .fill(glow)
                    .frame(width: size, height: size)
                    .blur(radius: 24)
                    .opacity(look == .paused ? 0 : 0.9)

                // Soft colored ring (the 7px rgba halo in the mockup)
                Circle()
                    .fill(glow.opacity(look == .paused ? 0 : 0.16))
                    .frame(width: size + 16, height: size + 16)

                // The button face: top-lit radial fill
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [top, bottom],
                            center: UnitPoint(x: 0.5, y: 0.36),
                            startRadius: 2,
                            endRadius: size * 0.62
                        )
                    )
                    .frame(width: size, height: size)
                    .overlay(
                        // inner top highlight
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.45), .clear],
                                    startPoint: .top, endPoint: .center
                                )
                            )
                            .blendMode(.softLight)
                    )
                    .overlay(Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1))
                    .shadow(color: .black.opacity(0.35), radius: 8, y: 4)

                Image(systemName: "power")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(glyphColor)
                    .shadow(color: .white.opacity(0.25), radius: 0.5, y: 0.5)
            }
            .frame(width: size + 24, height: size + 24)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel("stayup")
        .accessibilityValue(look == .active ? "Active" : look == .paused ? "Paused" : "Needs permission")
        .accessibilityHint("Toggles keeping you active")
    }
}
