import SwiftUI
import AppKit

@main
struct stayupApp: App {
    @StateObject private var controller = ActivityController.shared
    @StateObject private var launchAtLogin = LaunchAtLoginManager()
    @StateObject private var hotkey = HotkeyManager()

    init() {
        Task { await NotificationService.shared.requestPermission() }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .environmentObject(controller)
                .environmentObject(launchAtLogin)
        } label: {
            Image(systemName: controller.menuBarSymbol)
        }
        .menuBarExtraStyle(.window)
    }
}
