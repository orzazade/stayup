import AppKit
@preconcurrency import HotKey

/// Global hotkey (⌘⇧U) to toggle stayup Active/Paused without opening the menu.
@MainActor
final class HotkeyManager: ObservableObject {
    nonisolated(unsafe) private var hotKey: HotKey?

    init() {
        setup()
    }

    private func setup() {
        hotKey = HotKey(key: .u, modifiers: [.command, .shift])
        hotKey?.keyDownHandler = {
            Task { @MainActor in
                ActivityController.shared.toggle()
            }
        }
    }

    deinit {
        hotKey = nil
    }
}
