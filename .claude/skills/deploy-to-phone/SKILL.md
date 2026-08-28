---
name: Deploy to Phone
description: Build Victory Stars, run analyze/tests, and install the APK on the user's real Android phone over wireless adb (falls back to a connected emulator if no phone is reachable).
argument-hint: "[debug|release]"
allowed-tools: Bash(flutter *) Bash(adb *)
disable-model-invocation: true
---

# Deploy Victory Stars to the phone

Build mode: use the argument if given (`debug` or `release`), otherwise default to **release** —
that's what real-device testing in this project has used so far, and it's the build type that
actually surfaces plugin/resource bugs that debug mode hides (see the `tools:keep` fix in
`android/app/src/main/res/raw/keep.xml` — a real bug that only ever showed up in release builds).

Package name: `com.example.victory_stars`. Main activity exported name for a manual relaunch:
`.MainActivity`.

## 1. Checks first

Run, in order, stopping to report and ask before continuing if either fails:
- `flutter analyze`
- `flutter test`

Don't silently deploy on top of a failing check — but don't be rigid about it either; if the user
clearly just wants to see a WIP change on-device, a failing test unrelated to the change at hand
isn't necessarily a blocker. Use judgment, and say what failed either way.

## 2. Build

- Debug: `flutter build apk --debug` → `build/app/outputs/flutter-apk/app-debug.apk`
- Release: `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`

## 3. Get a device connected

Run `adb devices -l` first.

- If a device other than an `emulator-*` one is already listed as `device` (not `offline` or
  `unauthorized`), use it directly — skip straight to step 4.
- If nothing but emulators show up, the phone's wireless-debugging connection has likely expired
  (its port changes each time). Ask the user to open **Settings → Developer options → Wireless
  debugging** on the phone and read out the IP:port shown on that main screen, then run
  `adb connect <ip>:<port>`.
  - If `adb connect` succeeds, proceed.
  - If it's refused/fails (pairing itself expired, not just the connection), ask the user to open
    "Pair device with pairing code" instead, read out that screen's IP:port and 6-digit code, run
    `adb pair <ip>:<port> <code>`, then `adb connect` using the *main* wireless-debugging screen's
    IP:port (a different port from the pairing one).
- If there's truly no phone reachable (wireless debugging isn't available or the user doesn't want
  to bother), fall back to whatever emulator `adb devices` shows and say so explicitly — don't
  silently install to a different target than the user expects.

## 4. Install and launch

- `adb -s <device-serial> install -r build/app/outputs/flutter-apk/app-<mode>.apk`
- Launch it so it's ready to look at immediately:
  `adb -s <device-serial> shell monkey -p com.example.victory_stars -c android.intent.category.LAUNCHER 1`

## 5. Report

State plainly: which build mode, which device it went to, and whether analyze/tests passed clean.
If anything failed along the way, say exactly what and where — don't leave the user guessing
whether "deploy to phone" actually means it's on the phone now.
