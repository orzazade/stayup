import SwiftUI
import AppKit
import ApplicationServices

/// The brain. Owns the Active/Paused state machine, drives the 1-second tick
/// that reads idle time and fires the nudge, handles the duration timer,
/// screen-lock suspension, and schedule gating.
///
/// Single shared instance so the global hotkey can reach it without wiring.
@MainActor
final class ActivityController: ObservableObject {
    static let shared = ActivityController()

    enum Mode: Equatable { case paused, activeAlways, activeTimed }

    /// Duration the picker offers. `.always` = no timer.
    enum Duration: String, CaseIterable, Identifiable {
        case always, h1 = "1", h2 = "2", h4 = "4"
        var id: String { rawValue }
        var seconds: TimeInterval? {
            switch self {
            case .always: return nil
            case .h1: return 3600
            case .h2: return 7200
            case .h4: return 14400
            }
        }
        var label: String {
            switch self {
            case .always: return "Always"
            case .h1: return "1 hour"
            case .h2: return "2 hours"
            case .h4: return "4 hours"
            }
        }
    }

    // MARK: Published state (drives the UI)
    @Published private(set) var mode: Mode = .paused
    @Published private(set) var timerEnd: Date?
    @Published private(set) var idleSeconds: Int = 0
    @Published private(set) var isLocked: Bool = false
    @Published private(set) var isTrusted: Bool = PermissionManager.isTrusted()
    @Published var duration: Duration {
        didSet {
            UserDefaults.standard.set(duration.rawValue, forKey: "durationChoice")
            if isActive { applyActive() }  // re-arm with the new duration
        }
    }

    private nonisolated(unsafe) var timer: Timer?
    private var notifiedExpiry = false

    var isActive: Bool { mode != .paused }

    private init() {
        let rawDuration = UserDefaults.standard.string(forKey: "durationChoice") ?? Duration.always.rawValue
        self.duration = Duration(rawValue: rawDuration) ?? .always
        restoreState()
        observeSystemEvents()
        startTicking()
    }

    // MARK: User actions
    func toggle() {
        isActive ? pause() : applyActive()
    }

    /// Turn on using the currently selected duration.
    func applyActive() {
        if let secs = duration.seconds {
            mode = .activeTimed
            timerEnd = Date().addingTimeInterval(secs)
        } else {
            mode = .activeAlways
            timerEnd = nil
        }
        notifiedExpiry = false
        persist()
    }

    func pause() {
        mode = .paused
        timerEnd = nil
        persist()
    }

    func requestPermission() {
        PermissionManager.openAccessibilitySettings()
    }

    // MARK: Derived display values
    /// Seconds until the next nudge fires (the idle countdown). 0 when not active.
    var secondsUntilNudge: Int {
        guard isActive, !isLocked else { return 0 }
        return max(0, idleThreshold - idleSeconds)
    }

    /// Remaining time in a timed session, or nil when not timed.
    var timedRemaining: TimeInterval? {
        guard mode == .activeTimed, let end = timerEnd else { return nil }
        return max(0, end.timeIntervalSinceNow)
    }

    var menuBarSymbol: String {
        if !isTrusted { return "exclamationmark.circle" }
        return isActive ? "powercircle.fill" : "powercircle"
    }

    // MARK: Settings (read live from UserDefaults; the UI writes them via @AppStorage)
    private var idleThreshold: Int {
        let v = UserDefaults.standard.integer(forKey: "idleThreshold")
        return v == 0 ? 240 : v
    }
    private var scheduleEnabled: Bool { UserDefaults.standard.bool(forKey: "scheduleEnabled") }
    private var scheduleStart: Int {
        UserDefaults.standard.object(forKey: "scheduleStartHour") as? Int ?? 9
    }
    private var scheduleEnd: Int {
        UserDefaults.standard.object(forKey: "scheduleEndHour") as? Int ?? 18
    }
    private var scheduleWeekdaysOnly: Bool {
        UserDefaults.standard.object(forKey: "scheduleWeekdaysOnly") as? Bool ?? true
    }

    // MARK: The tick
    private func startTicking() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        timer?.tolerance = 0.2
        tick()
    }

    private func tick() {
        isTrusted = PermissionManager.isTrusted()
        idleSeconds = Int(IdleMonitor.idleSeconds())

        if expireIfNeeded() { return }

        guard shouldNudgeNow() else { return }
        if idleSeconds >= idleThreshold {
            ActivityInjector.nudge()
        }
    }

    /// Returns true if a timed session just expired (and was paused).
    @discardableResult
    private func expireIfNeeded() -> Bool {
        guard mode == .activeTimed, let end = timerEnd, Date() >= end else { return false }
        pause()
        if !notifiedExpiry {
            notifiedExpiry = true
            Task { await NotificationService.shared.notifySessionEnded() }
        }
        return true
    }

    private func shouldNudgeNow() -> Bool {
        guard isActive, isTrusted, !isLocked else { return false }
        // A timed session is an explicit override — it ignores the schedule.
        if mode == .activeTimed { return true }
        if scheduleEnabled {
            return ScheduleManager.isWithin(
                startHour: scheduleStart,
                endHour: scheduleEnd,
                weekdaysOnly: scheduleWeekdaysOnly
            )
        }
        return true
    }

    // MARK: State persistence
    private func restoreState() {
        let raw = UserDefaults.standard.string(forKey: "mode") ?? "paused"
        switch raw {
        case "always":
            mode = .activeAlways
        case "timed":
            if let end = UserDefaults.standard.object(forKey: "timerEnd") as? Date, end > Date() {
                mode = .activeTimed
                timerEnd = end
            } else {
                mode = .paused
            }
        default:
            mode = .paused
        }
        persist()
    }

    private func persist() {
        let raw: String
        switch mode {
        case .paused: raw = "paused"
        case .activeAlways: raw = "always"
        case .activeTimed: raw = "timed"
        }
        UserDefaults.standard.set(raw, forKey: "mode")
        if let timerEnd {
            UserDefaults.standard.set(timerEnd, forKey: "timerEnd")
        } else {
            UserDefaults.standard.removeObject(forKey: "timerEnd")
        }
    }

    // MARK: Lock / wake handling
    private func observeSystemEvents() {
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(forName: .init("com.apple.screenIsLocked"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.isLocked = true }
        }
        dnc.addObserver(forName: .init("com.apple.screenIsUnlocked"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.handleWakeOrUnlock() }
        }
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.handleWakeOrUnlock() }
        }
    }

    /// On unlock or wake, clear the lock flag and recompute expiry from the
    /// stored wall-clock end Date (a closed lid must not extend the session).
    private func handleWakeOrUnlock() {
        isLocked = false
        expireIfNeeded()
    }

    deinit {
        timer?.invalidate()
    }
}
