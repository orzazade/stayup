import SwiftUI

@main
struct stayupApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    // The menu bar presence is managed by AppDelegate (NSStatusItem + NSPopover,
    // for the native arrow). This empty Settings scene keeps the app an
    // LSUIElement accessory with no main window.
    var body: some Scene {
        Settings { EmptyView() }
    }
}
