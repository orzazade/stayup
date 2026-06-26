import Foundation
import ServiceManagement
import SwiftUI

/// Toggles "Launch at Login" via SMAppService. Copied from the pzap pattern.
@MainActor
final class LaunchAtLoginManager: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            guard oldValue != isEnabled else { return }
            updateSystemState(isEnabled)
        }
    }

    init() {
        self.isEnabled = (SMAppService.mainApp.status == .enabled)
        UserDefaults.standard.set(isEnabled, forKey: "launchAtLogin")
    }

    private func updateSystemState(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
                UserDefaults.standard.set(true, forKey: "launchAtLogin")
            } else {
                try SMAppService.mainApp.unregister()
                UserDefaults.standard.set(false, forKey: "launchAtLogin")
            }
        } catch {
            isEnabled = !enabled  // revert on failure
            print("Launch at login failed: \(error)")
        }
    }
}
