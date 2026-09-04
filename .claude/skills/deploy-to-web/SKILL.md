---
name: deploy-to-web
description: Build Victory Stars, run analyze/tests, and (re)launch it in the browser — closing and relaunching the same dev Chrome window rather than piling up new ones, so the user's browser is always left showing the latest build.
argument-hint: "[debug|release]"
allowed-tools: Bash(flutter *) Bash(taskkill *) PowerShell(Get-Process *) PowerShell(Get-CimInstance *)
disable-model-invocation: true
---

# Deploy Victory Stars to the browser

Build mode: use the argument if given (`debug` or `release`), otherwise default to **debug** — the
web target has no separate real-device install step the way the phone does, so debug's hot-reload
dev server (`flutter run -d chrome`) is the normal way to look at it, not just a fallback.

## The one thing to always get right: reuse the browser window

`flutter run -d chrome` always launches its own **fresh, temporary** Chrome profile (a
`--user-data-dir` under the system temp folder, with its own `--remote-debugging-port`) — there is
no way to hot-reload a *backgrounded* `flutter run` process from this environment (stdin isn't wired
to it; a raw Win32 `WriteConsoleInput` keystroke injection was tried and confirmed not to work), so
don't attempt that. The only reliable way to push an update is to **kill the previous flutter-web
process and its Chrome window, then start a fresh one** — this is what "update the browser" means
here, not opening an additional new window alongside the old one.

Because each relaunch is a brand-new Chrome profile, **localStorage is empty every time** — the
user's projects/stars/constellations won't be there after a redeploy unless they're re-added by
hand in that session. That's expected for this dev-preview workflow; don't try to work around it
(e.g. don't seed fake data into it unless the user is specifically asking you to test something,
not just asking you to deploy their real work).

### Steps

1. **Checks first** — same as the phone skill: run `flutter analyze` then `flutter test`, in order,
   stopping to report and ask before continuing if either fails (unless the user clearly just wants
   to eyeball a WIP change).

2. **Find and kill any previous flutter-web session:**
   - `Get-CimInstance Win32_Process -Filter "Name='chrome.exe'" | Where-Object { $_.CommandLine -like '*remote-debugging-port*' }` — any Chrome process matching this is a `flutter run -d chrome` window from an earlier deploy. Kill it (`taskkill /F /PID <id>`).
   - Also kill the `dart.exe`/`dartvm.exe` process actually running `flutter run -d chrome` (look for `Get-Process` entries with a recent `StartTime` matching the last deploy, or just kill by the background task's own process if you started it yourself this session).
   - It's fine to be a little aggressive here — these are always disposable dev-server processes, never something with unsaved user work in them.

3. **Launch fresh:** run `flutter run -d chrome` (add `--release` if release mode was requested) as
   a background command. Wait for `Debug service listening on ws://...` to appear in its output
   before considering it ready — that's the signal the web app has actually loaded, not just that
   the process started.

4. **Report:** which build mode, and that the browser window now shows the latest build (mention
   that any previously-entered test data is gone, per the note above, so the user isn't confused
   seeing an empty app).

Don't seed localStorage, don't take screenshots, don't drive the page via CDP as part of this
skill — that's testing infrastructure for a *different* purpose (verifying a specific bug fix),
not part of a plain "deploy" request. Just get the build running and the window ready to look at.
