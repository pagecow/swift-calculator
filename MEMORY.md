# Project memory

Durable lessons recorded by coding agents working in this project. The engine reads this file at the start of every session and shows it to the next agent — append anything the next session should know.


## 2026-10-10 12:40:45

## SwiftCalculator — how this project was bootstrapped

**There is no Apple CLI project scaffolder.** No `create-swift-app` equivalent exists;
`xcodebuild`/`swift` build projects but never create them. This `.xcodeproj` is
**hand-written** (`SwiftCalculator.xcodeproj/project.pbxproj`), so if it ever looks
"unusual" that is why — it was not produced by Xcode's New Project dialog.

What made that tractable: `objectVersion = 77` + a **`PBXFileSystemSynchronizedRootGroup`**
pointing at `SwiftCalculator/`. Xcode then classifies files by type itself (`.swift` →
Sources, `.xcassets` → Resources), so the pbxproj has **no PBXFileReference or
PBXBuildFile entries at all** and never needs editing when files are added. Don't
"fix" the empty `files = ()` build phases — that is intentional.

Gotchas hit / worth remembering:

- `xcodebuild -list -project …` is the fastest way to prove a hand-written pbxproj
  parses (targets + configs + schemes) before paying for a full build.
- The shared scheme at `xcshareddata/xcschemes/SwiftCalculator.xcscheme` is required for
  `-scheme`; its `BlueprintIdentifier` must match the PBXNativeTarget UUID exactly
  (currently `CA1C000000000000000000A5`).
- Deployment target is iOS 18.0; simulators available here are iOS 18.1 / 18.3 / 26.0 /
  26.3. `iPhone 17` on iOS 26.0 is the one that was used to verify.
- Only build "warning" is the harmless `appintentsmetadataprocessor … no
  AppIntents.framework dependency found`.
- App icon has **no artwork** — `AppIcon.appiconset` has an empty 1024×1024 slot. This
  builds and runs fine, but the icon is blank.

### Verifying without an Xcode test target

`CalculatorEngine.swift` deliberately imports no SwiftUI, so it compiles straight with
the toolchain and can be exercised as a script — this is the fast feedback loop:

```bash
swiftc SwiftCalculator/CalculatorEngine.swift tmp/scratch/engine-check/main.swift \
  -o tmp/scratch/engine-check/run && tmp/scratch/engine-check/run
```

End-to-end proof (install + launch + screenshot) went through `xcrun simctl`, no
simulator UI app needed:

```bash
xcrun simctl boot "iPhone 17" && xcrun simctl bootstatus "iPhone 17" -b
xcrun simctl install booted <path>/SwiftCalculator.app
xcrun simctl launch booted com.example.SwiftCalculator
xcrun simctl io booted screenshot tmp/scratch/calculator.png
```

There is still **no committed test target** — the checks above live in gitignored
`tmp/scratch/engine-check/`. Promoting them to a real XCTest unit-test target is the
natural next step.

### History

This folder previously held the ChatOSS `.aip` **web-app** starter template (HTML/CSS/JS,
named "Swift Calculator" with id `com.example.swift-calculator`). It was moved — not
deleted — to `tmp/scratch/webapp-template-backup/` on the user's instruction when the
SwiftUI project was created. `tmp/` is gitignored, so it is local-only.

## 2026-10-12 10:05:17

### Xcode 27 removed Simulator.app — the UI app is now Device Hub

`open -a Simulator` **fails** on this machine ("Unable to find application named
'Simulator'"). Xcode 27 deleted `Simulator.app` and ships **DeviceHub.app** ("Device Hub")
instead. Verified here:

| | ≤ Xcode 26 | Xcode 27 |
| --- | --- | --- |
| App on disk | `Simulator.app` | `DeviceHub.app` |
| Bundle id | `com.apple.iphonesimulator` | `com.apple.dt.Devices` |
| Location | `Xcode.app/Contents/Developer/Applications/` | `Xcode.app/Contents/Applications/` |
| Process name | `Simulator` | `DeviceHub` |

Working commands (both verified): `open -b com.apple.dt.Devices` or `open -a "Device Hub"`.
Absolute path: `/Applications/Xcode.app/Contents/Applications/DeviceHub.app`.

**`simctl` is completely unchanged** — `list` / `boot` / `install` / `launch` /
`io screenshot` all behave exactly as before, so the CLI verification loop needs no
changes. `devicectl` additionally manages simulators now. Anything that resolves the UI
app *by name* breaks (Expo Orbit needed a patch for this).

Also: **three simulators are usually booted at once here** (iPhone 17 Pro, iPhone 18 Pro,
iPhone 17). `simctl`'s `booted` keyword then resolves to one of them arbitrarily — target
by name or UDID when it matters, and read `simctl get_app_container` output to confirm
which device you actually installed on.
