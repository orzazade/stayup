import SwiftUI
import AppKit
import ApplicationServices
import IOKit.pwr_mgt

/// The brain. Owns the Active/Paused state machine, drives the 1-second tick
/// that reads idle time and fires the nudge, handles the duration timer and
/// schedule gating, and — while Active — holds an IOKit power assertion so the
/// Mac doesn't idle-sleep (sleeping would stop the nudge and drop you to Away).
///
/// Single shared instance so the global hotkey can reach it without wiring.
@MainActor
final class ActivityController: ObservableObject {
    static let shared = ActivityController()

    enum Mode: Equatable { case paused, activeAlways, activeTimed }

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

    // MARK: Published state
    @Published private(set) var mode: Mode = .paused
    @Published private(set) var timerEnd: Date?
    @Published private(set) var idleSeconds: Int = 0
    @Published private(set) var isTrusted: Bool = PermissionManager.isTrusted()
    /// True when we're firing nudges but they're provably not landing (the idle
    /// clock doesn't reset). This happens when `AXIsProcessTrusted()` reports
    /// granted but the kernel still drops the event — e.g. a re-signed build
    /// whose cdhash no longer matches the recorded Accessibility grant. The
    /// power assertion needs no permission and keeps holding, so without this
    /// check the user sees a green button while actually showing Away.
    @Published private(set) var nudgeBlocked: Bool = false
    @Published var duration: Duration {
        didSet {
            UserDefaults.standard.set(duration.rawValue, forKey: "durationChoice")
            if isActive { applyActive() }
        }
    }

    private nonisolated(unsafe) var timer: Timer?
    private var notifiedExpiry = false

    // Nudge self-verification: a working nudge resets the idle clock toward 0.
    // If after firing it the clock stayed put, the event was dropped.
    private var awaitingNudgeVerify = false
    private var idleAtNudge = 0
    private var nudgeFailureStreak = 0

    // Power assertion (keep the screen on — and Mac awake — while Active, so it
    // never locks and the nudge keeps you green even when you step away).
    private var sleepAssertionID: IOPMAssertionID = 0

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

    func applyActive() {
        if let secs = duration.seconds {
            mode = .activeTimed
            timerEnd = Date().addingTimeInterval(secs)
        } else {
            mode = .activeAlways
            timerEnd = nil
        }
        notifiedExpiry = false
        resetNudgeVerification()
        persist()
        reconcilePowerAssertion()
    }

    func pause() {
        mode = .paused
        timerEnd = nil
        resetNudgeVerification()
        persist()
        reconcilePowerAssertion()
    }

    func requestPermission() {
        PermissionManager.openAccessibilitySettings()
    }

    // MARK: Derived display values
    var secondsUntilNudge: Int {
        guard isActive else { return 0 }
        return max(0, idleThreshold - idleSeconds)
    }

    var timedRemaining: TimeInterval? {
        guard mode == .activeTimed, let end = timerEnd else { return nil }
        return max(0, end.timeIntervalSinceNow)
    }

    var menuBarSymbol: String {
        if !isTrusted || (isActive && nudgeBlocked) { return "exclamationmark.circle" }
        return isActive ? "power.circle.fill" : "power.circle"
    }

    /// Active, but the nudge is provably not landing — show a warning, not green.
    var isNotWorking: Bool { isActive && nudgeBlocked }

    // MARK: Settings (read live from UserDefaults; the UI writes them via @AppStorage)
    private var idleThreshold: Int {
        let v = UserDefaults.standard.integer(forKey: "idleThreshold")
        return v == 0 ? 240 : v
    }
    private var scheduleEnabled: Bool { UserDefaults.standard.bool(forKey: "scheduleEnabled") }
    private var scheduleStart: Int { UserDefaults.standard.object(forKey: "scheduleStartHour") as? Int ?? 9 }
    private var scheduleEnd: Int { UserDefaults.standard.object(forKey: "scheduleEndHour") as? Int ?? 18 }
    private var scheduleWeekdaysOnly: Bool { UserDefaults.standard.object(forKey: "scheduleWeekdaysOnly") as? Bool ?? true }

    // MARK: The tick
    private func startTicking() {
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        t.tolerance = 0.2
        RunLoop.main.add(t, forMode: .common)
        timer = t
        tick()
    }

    private func tick() {
        isTrusted = PermissionManager.isTrusted()
        idleSeconds = Int(IdleMonitor.idleSeconds())

        verifyLastNudge()

        if expireIfNeeded() { return }

        reconcilePowerAssertion()

        guard shouldNudgeNow() else { return }
        if idleSeconds >= idleThreshold {
            idleAtNudge = idleSeconds
            ActivityInjector.nudge()
            awaitingNudgeVerify = true
        }
    }

    /// Confirm the previous tick's nudge actually moved the needle. A working
    /// nudge resets the idle clock, so by this tick `idleSeconds` should have
    /// dropped well below where it was when we fired. If it instead held or
    /// climbed, the event was dropped (granted-but-cdhash-mismatch, or macOS
    /// hardening). Require two strikes so one slow/jittery tick can't false-alarm.
    private func verifyLastNudge() {
        guard awaitingNudgeVerify else { return }
        awaitingNudgeVerify = false
        if idleSeconds >= idleAtNudge {
            nudgeFailureStreak += 1
        } else {
            nudgeFailureStreak = 0
        }
        nudgeBlocked = nudgeFailureStreak >= 2
    }

    private func resetNudgeVerification() {
        awaitingNudgeVerify = false
        idleAtNudge = 0
        nudgeFailureStreak = 0
        nudgeBlocked = false
    }

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

    /// Whether stayup should be actively keeping you up right now. Lock state is
    /// intentionally NOT considered — while Active, stayup keeps you online
    /// regardless of whether the screen is locked.
    private func shouldNudgeNow() -> Bool {
        guard isActive, isTrusted else { return false }
        if mode == .activeTimed { return true }  // timer overrides the schedule
        if scheduleEnabled {
            return ScheduleManager.isWithin(
                startHour: scheduleStart, endHour: scheduleEnd, weekdaysOnly: scheduleWeekdaysOnly)
        }
        return true
    }

    // MARK: Power assertion (keep awake)
    /// While active, prevent display sleep — this keeps the screen on so the Mac
    /// never locks, which is the only way the nudge can keep you green when you
    /// step away (macOS ignores synthetic input once the screen is locked).
    private func reconcilePowerAssertion() {
        if shouldNudgeNow() {
            guard sleepAssertionID == 0 else { return }  // already held
            var id: IOPMAssertionID = 0
            let r = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                "stayup is keeping you active" as CFString, &id)
            if r == kIOReturnSuccess { sleepAssertionID = id }
        } else {
            releaseAssertion()
        }
    }

    private func releaseAssertion() {
        if sleepAssertionID != 0 {
            IOPMAssertionRelease(sleepAssertionID)
            sleepAssertionID = 0
        }
    }

    // MARK: State persistence
    private func restoreState() {
        // Always start Paused. The user explicitly turns stayup on each session.
        mode = .paused
        timerEnd = nil
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

    // MARK: Wake handling (recompute timed expiry from wall-clock on wake)
    private func observeSystemEvents() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.expireIfNeeded() }
        }
    }

    deinit {
        timer?.invalidate()
        if sleepAssertionID != 0 { IOPMAssertionRelease(sleepAssertionID) }
    }
}
