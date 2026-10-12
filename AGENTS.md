# SwiftCalculator — project notes for agents

## What this is

A SwiftUI iOS calculator app. Plain Xcode project, no package manager, no
dependencies, no build step beyond Xcode itself.

- Project: `SwiftCalculator.xcodeproj` (shared scheme `SwiftCalculator`)
- Sources: `SwiftCalculator/` — the target uses an Xcode **file system
  synchronized group**, so any file dropped into that folder is compiled
  automatically. No `project.pbxproj` edit is needed to add a Swift file
  or an asset catalog.
- Deployment target: iOS 18.0. Built and verified with Xcode 27 / Swift 6.4.

## Layout

| File | Role |
| --- | --- |
| `SwiftCalculator/SwiftCalculatorApp.swift` | `@main` entry point, opens `ContentView` |
| `SwiftCalculator/CalculatorEngine.swift` | `@Observable` calculator state machine — no SwiftUI imports |
| `SwiftCalculator/ContentView.swift` | Display + 4-column keypad, plus the private `KeyButton` view |
| `SwiftCalculator/Assets.xcassets` | App icon (no artwork yet) and the orange accent color |
| `SwiftCalculator/Preview Content` | Preview-only assets, excluded from release builds |

## Build, test, run

Simulator build (fast check that everything compiles):

```bash
xcodebuild -project SwiftCalculator.xcodeproj -scheme SwiftCalculator \
  -destination 'generic/platform=iOS Simulator' -configuration Debug build
```

Run it on a simulator end to end:

```bash
xcrun simctl boot "iPhone 17"
xcodebuild -project SwiftCalculator.xcodeproj -scheme SwiftCalculator \
  -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build
xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/SwiftCalculator-*/Build/Products/Debug-iphonesimulator/SwiftCalculator.app
xcrun simctl launch booted com.example.SwiftCalculator
xcrun simctl io booted screenshot tmp/scratch/calculator.png
```

To watch it on screen, open **Device Hub** — Xcode 27 removed `Simulator.app`, so
`open -a Simulator` fails with "Unable to find application named 'Simulator'":

```bash
open -b com.apple.dt.Devices
```

There are no unit tests yet. The engine was written to be testable — see below.

## Conventions

- `CalculatorEngine` holds all arithmetic and stays free of SwiftUI, so it can
  be unit-tested directly. Add UI-only code to `ContentView.swift`.
- The display string is formatted once, in `CalculatorEngine.format(_:)`
  (thousands separator, max 8 decimals). `nan` renders as `Error`.
- Keep `tmp/` for scratch files — it is gitignored.

## History

The folder originally held a ChatOSS `.aip` web-app template (HTML/CSS/JS,
named "Swift Calculator"). It was moved to
`tmp/scratch/webapp-template-backup/` when this Xcode project was created.
