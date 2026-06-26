# stayup — Go-Live Checklist

Distribution model: **Developer ID + notarized, direct download + Homebrew cask.**
NOT the Mac App Store (App Sandbox forbids Accessibility + global CGEvent posting).

Legend: `[ ]` todo · `[~]` partial · `[x]` done

---

## 0. Distribution decision
- [x] Confirmed: Mac App Store is not viable (sandbox blocks the core mechanism)
- [x] Path chosen: Developer ID Application, notarized, hardened runtime, non-sandboxed
- [ ] Decide bundle id stays `com.scifi.stayup` (or switch to a domain you own, e.g. `space.scifilab.stayup`)

## 1. Assets & branding  ← "fix assets"
- [x] **App icon** — dark squircle + glowing green power button. `dist/make-icon.swift` →
      `dist/AppIcon.icns` (all sizes via iconutil). Source-reproducible.
- [x] Wire icon into the bundle: `CFBundleIconFile=AppIcon` in `dist/Info.plist`, copied in `dist/build.sh`
- [ ] **Menu bar glyph** — confirm the colored power-circle reads well at 1x on light + dark menu bars;
      consider a custom template variant if SF Symbol feels off
- [ ] **README hero** — logo image + one-line pitch (currently text only)
- [ ] **Demo GIF** — 5–8s: open popover → tap green → idle countdown → stays Available in Teams
- [ ] **Screenshots** — popover (active/paused/setup), Advanced expanded — for README + release notes
- [ ] App display name / menu bar tooltip copy final pass

## 2. Code signing & notarization
- [ ] Create/confirm **Developer ID Application** certificate in your Apple Developer account
- [ ] `export SIGNING_IDENTITY="Developer ID Application: <Name> (<TEAMID>)"`
- [ ] Hardened runtime enabled (sign with `--options runtime` — already in `dist/sign.sh`)
- [ ] Entitlements: none required for CGEvent posting (TCC Accessibility is user-granted, not an entitlement).
      Verify no `com.apple.security.*` needed; do NOT add App Sandbox.
- [ ] Create an **app-specific password** (appleid.apple.com) for notarytool
- [ ] `export APPLE_ID=… TEAM_ID=… APP_SPECIFIC_PASSWORD=…`
- [ ] Run `./dist/build.sh && ./dist/sign.sh && ./dist/notarize.sh` → notarized, stapled `stayup.app`
- [ ] Verify: `spctl -a -vvv dist/stayup.app` → "accepted, source=Notarized Developer ID"
- [ ] Verify: `codesign -dv --verbose=4 dist/stayup.app` → Developer ID, hardened runtime, secure timestamp

## 3. Permissions UX (must be solid before public)
- [ ] First-run Accessibility onboarding flow tested end-to-end on a clean machine/user
- [ ] Denied-permission state surfaces clearly (yellow icon + setup screen + re-open Settings)
- [ ] After grant, app activates without a manual relaunch (or instructs to relaunch if TCC lags)
- [ ] Notarized build: grant persists across app updates (stable signature) — confirm

## 4. Functional QA (real-world)
- [ ] **Live Teams test** — stays Available across the idle threshold (the core promise)
- [ ] Live Slack test
- [ ] Screen lock → nudging suspends; unlock → resumes
- [ ] Sleep/wake → timed session expiry recomputed from wall-clock (no extension)
- [ ] Duration timer: 1h/2h/4h start, countdown, expiry → Paused + notification
- [ ] Work-hours schedule gates correctly (in/out of window, weekday/weekend)
- [ ] Launch-at-login registers and actually launches on reboot
- [ ] Multi-monitor: cursor nudge works regardless of active display
- [ ] Quit + relaunch starts Paused (intended)
- [ ] Tidy the "Nudge after idle" sub-minute label (30s vs "0 min") — already fixed, re-verify
- [ ] Battery: 1s tick is fine, but confirm no measurable drain over an hour

## 5. Release engineering
- [ ] Bump version (Info.plist + cask) to `1.0.0`
- [ ] Build universal (arm64 + x86_64) — `dist/build.sh` already does this
- [ ] `stayup-1.0.0.zip` + `sha256.txt` from `notarize.sh`
- [ ] Create **GitHub Release** `v1.0.0` with the notarized zip + release notes
- [ ] Create **`orzazade/homebrew-tap`** repo; add `Casks/stayup.rb` with real version + sha256 + URL
- [ ] Test install on a clean machine: `brew install --cask orzazade/tap/stayup`
- [ ] (Later) Consider submitting to `homebrew-cask` core once it has traction

## 6. Docs & legal
- [x] LICENSE (MIT)
- [ ] README final: install (brew + manual), first-run permission steps, FAQ ("is this a cheat tool?" → honesty framing)
- [ ] PRIVACY note: **no network, no telemetry, no data collected** — state it plainly (it's a selling point)
- [ ] CONTRIBUTING.md (build/run/test instructions) — optional but nice for OSS
- [ ] CHANGELOG.md starting at 1.0.0

## 7. CI/CD (optional but recommended)
- [x] CI builds on push (macos-15, Swift 6)
- [ ] Add a **release workflow**: on tag `v*`, build + sign + notarize + attach zip to the GitHub Release
      (store signing secrets in GitHub Actions secrets: cert .p12 base64, password, APPLE_ID, TEAM_ID, app pw)
- [ ] Auto-update the Homebrew cask on release (PR bot or script)

## 8. Launch
- [ ] "Show HN: stayup — stay Available in Teams/Slack, honestly" post
- [ ] r/macapps post with the demo GIF
- [ ] Optional landing page (e.g. on scifilab.space) with download + GIF

---

## Quick path to a shippable v1.0.0 (minimum)
1. App icon (§1) → 2. Sign + notarize (§2) → 3. Live Teams QA (§4) →
4. GitHub Release + cask (§5) → 5. README + privacy (§6). Everything else is polish.
