# Changelog

All notable changes to stayup are documented here.

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
- **Keeps your Mac awake** — while active, holds an IOKit power assertion so the Mac
  doesn't idle-sleep (the nudge keeps firing even with the screen off).
- **Keep screen on** (optional toggle) — prevents display sleep so the Mac never *locks*;
  needed to stay green while away, because macOS ignores synthetic input once the screen
  is locked (with it off, you go Away when it locks).
- **Colored menu bar status icon** reflecting state at a glance.
- **Launch at login** and a global hotkey (⌘⇧U) to toggle.
- **Accessibility onboarding** with a clear permission gate.
- Universal binary (Apple Silicon + Intel), macOS 13+.

### Notes
- Distributed outside the Mac App Store (Developer ID, notarized) because the Accessibility
  mechanism that makes stayup work is forbidden by the App Sandbox the App Store requires.

[1.0.0]: https://github.com/orzazade/stayup/releases/tag/v1.0.0
