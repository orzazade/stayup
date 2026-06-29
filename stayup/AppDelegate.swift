import SwiftUI
import AppKit
import Combine

/// Hosting controller that animates the NSPopover resize. Whenever SwiftUI
/// reports a new content size (Advanced expands, Schedule sub-section opens,
/// etc.), the change is run inside an NSAnimationContext so the popover grows
/// or shrinks smoothly instead of snapping. The first size and any resize while
/// the popover is closed are applied instantly.
final class AnimatingHostingController<Content: View>: NSHostingController<Content> {
    var shouldAnimate: () -> Bool = { false }
    private var hasInitialSize = false

    override var preferredContentSize: NSSize {
        get { super.preferredContentSize }
        set {
            guard newValue != super.preferredContentSize, newValue.height > 0 else {
                super.preferredContentSize = newValue
                return
            }
            if hasInitialSize && shouldAnimate() {
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.32
                    ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    ctx.allowsImplicitAnimation = true
                    super.preferredContentSize = newValue
                }
            } else {
                super.preferredContentSize = newValue
                hasInitialSize = true
            }
        }
    }
}

/// Drives the menu bar presence with a manual NSStatusItem + NSPopover so the
/// popover gets the native arrow pointing up at the icon (MenuBarExtra's window
/// style draws a plain panel with no arrow). The popover hosts the SwiftUI
/// MenuView and auto-sizes as Advanced expands.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private let controller = ActivityController.shared
    private let launchAtLogin = LaunchAtLoginManager()
    private let hotkey = HotkeyManager()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Popover hosting the SwiftUI menu; .preferredContentSize keeps the
        // popover sized to the view as Advanced expands/collapses.
        let host = AnimatingHostingController(
            rootView: MenuView()
                .environmentObject(controller)
                .environmentObject(launchAtLogin)
        )
        host.sizingOptions = [.preferredContentSize]
        host.shouldAnimate = { [weak self] in self?.popover.isShown ?? false }
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = host

        // Status bar item.
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        updateIcon()

        // Keep the menu bar glyph in sync with Active/Paused/Setup.
        controller.objectWillChange
            .sink { [weak self] in
                Task { @MainActor in self?.updateIcon() }
            }
            .store(in: &cancellables)

        Task { await NotificationService.shared.requestPermission() }
    }

    /// Colored status icon: green = Active, grey = Paused, yellow "!" = setup.
    /// White glyph on a colored disc (traffic-light style), a touch larger than
    /// the default menu bar symbol size.
    private func updateIcon() {
        let name: String
        let color: NSColor
        let state: String
        if !controller.isTrusted {
            name = "exclamationmark.circle.fill"; color = .systemYellow; state = "setup needed"
        } else if controller.isNotWorking {
            name = "exclamationmark.circle.fill"; color = .systemYellow; state = "not working — re-grant access"
        } else if controller.isActive {
            name = "power.circle.fill"; color = .systemGreen; state = "active"
        } else {
            name = "power.circle.fill"; color = .systemGray; state = "paused"
        }
        guard let button = statusItem?.button else { return }
        button.image = coloredSymbol(name, color, label: "stayup, \(state)")
        button.toolTip = "stayup — \(state)"
    }

    private func coloredSymbol(_ name: String, _ color: NSColor, label: String) -> NSImage? {
        // Fall back to a guaranteed-valid symbol so the item can never become
        // a zero-width (invisible) button from a bad symbol name.
        let base = NSImage(systemSymbolName: name, accessibilityDescription: label)
            ?? NSImage(systemSymbolName: "power", accessibilityDescription: label)
        // Two-color palette: white glyph + colored disc, so the inner symbol
        // stays visible instead of becoming a transparent cutout.
        let config = NSImage.SymbolConfiguration(pointSize: 17, weight: .regular)
            .applying(NSImage.SymbolConfiguration(paletteColors: [.white, color]))
        let image = base?.withSymbolConfiguration(config)
        image?.isTemplate = false  // non-template so the colors actually show
        return image
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
