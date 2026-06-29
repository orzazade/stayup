# Changelog

All notable changes to stayup are documented here.

## [1.0.1] — 2026-06-29

### Fixed
- **Never show green when the nudge isn't actually working.** `AXIsProcessTrusted()`
  can report Accessibility as granted for a re-signed build whose signature no longer
  matches the recorded grant — so the button went green and the screen stayed on while
  macOS silently dropped the cursor nudge, leaving you shown as **Away**. stayup now
  verifies each nudge actually reset the idle clock; if it didn't, it shows a clear
  **"Not working — re-grant Accessibility"** warning (yellow icon, amber button) instead
  of a misleading green.

[1.0.1]: https://github.com/orzazade/stayup/releases/tag/v1.0.1

## [1.0.0] — 2026-06-26

First public release.

### Added
- **One big green power button** in the menu bar — tap to stay Available in Teams & Slack.
  Glowing green = Active, dim grey = Paused, yellow = needs setup.
- **Honest by design** — stayup never reads, sets, or reports your Teams/Slack status. It only
  stops macOS from marking you idle after brief inactivity. Zero network calls, zero telemetry.
- **Native activity nudge** — a net-zero one-pixel cursor move resets the input-idle timer that
  Teams/Slack read, so you stay Available without the cursor visibly moving.
- **Timed sessions** — keep active for 1h / 2h / 4h, then auto-pause (with a notification).
- **Work-hours schedule** — optionally only stay active Mon–Fri during set hours.
- **Stays green when you step away** — while active, holds an IOKit power assertion that
  keeps the screen on so the Mac never locks (macOS ignores synthetic input once locked, so
  keeping the display awake is the only way the nudge can keep you Available hands-off).
- **Colored menu bar status icon** reflecting state at a glance.
- **Launch at login** and a global hotkey (⌘⇧U) to toggle.
- **Accessibility onboarding** with a clear permission gate.
- Universal binary (Apple Silicon + Intel), macOS 13+.

### Notes
- Distributed outside the Mac App Store (Developer ID, notarized) because the Accessibility
  mechanism that makes stayup work is forbidden by the App Sandbox the App Store requires.

[1.0.0]: https://github.com/orzazade/stayup/releases/tag/v1.0.0
