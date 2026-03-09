
       🧽 cleann-mi-maccc                              
                                                                        
       free & open-source macOS system cleaner                          
       a CleanMyMac clone — no subscription, no telemetry, no bs        

[![Build](https://github.com/mysterion04/clean-my-mac/actions/workflows/build/badge.svg)](https://github.com/mysterion04/clean-my-mac/actions)
![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)
![Swift](https://img.shields.io/badge/swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

 ### **CleanMyMac charges $35/year for this. This is free. It does the same things.**

### [⬇️ Download cleann-mi-maccc.dmg — Latest Release](https://github.com/mysterion04/clean-my-mac/releases/latest)

> Open the DMG → drag to `/Applications` → run `xattr -cr /Applications/CleanMyMac.app` → done.

---

**cleann-mi-maccc** is a fully free, open-source drop-in for CleanMyMac. Built from scratch in Swift + SwiftUI. No account required. No background processes. No phoning home. Just a fast, dark-mode native app that cleans your Mac.

---

## Features

```
  ┌──────────────────────┬─────────────────────────────────────────────────┐
  │  🗑  Junk Scanner    │  6 parallel scan categories: caches, logs,      │
  │                      │  temp files, broken downloads, language packs,  │
  │                      │  and dev junk. Select-all per group.            │
  ├──────────────────────┼─────────────────────────────────────────────────┤
  │  📦  App Uninstaller │  Scans /Applications, finds every residual file │
  │                      │  in ~/Library by bundle ID, and trashes them    │
  │                      │  all in one shot.                               │
  ├──────────────────────┼─────────────────────────────────────────────────┤
  │  💾  Disk Analyzer   │  Swift Charts donut + bar breakdown of your     │
  │                      │  entire disk. See exactly what's eating space.  │
  ├──────────────────────┼─────────────────────────────────────────────────┤
  │  🔍  Large Files     │  Recursive scan from ~/ with a size threshold   │
  │                      │  slider, extension filter chips, and bulk       │
  │                      │  select + trash.                                │
  └──────────────────────┴─────────────────────────────────────────────────┘
```

---

## Install

### Option 1 — Download DMG (easiest)

1. Go to [**Releases**](https://github.com/mysterion04/clean-my-mac/releases) and download `cleann-mi-maccc.dmg`
2. Open the DMG
3. Drag **CleanMyMac.app** into your `/Applications` folder
4. Follow the Gatekeeper step below

### Bypass Gatekeeper

Because the app is not notarized (it's free and open source, not sold on the App Store), macOS will say it is **"damaged"** when you try to open it. It is not damaged — macOS is just suspicious of unsigned apps downloaded from the internet.

**Fix it with one command:**

```bash
xattr -cr /Applications/CleanMyMac.app
```

Then double-click the app. It will open normally.

> **Why does this happen?**
> macOS adds a `com.apple.quarantine` extended attribute to any file downloaded from the internet. For unsigned apps, instead of showing the usual "Open Anyway" button, it shows "damaged". The `xattr -cr` command strips that quarantine flag.

---

### Option 2 — Build from source

Requires **Xcode 15+** and macOS 14+.

```bash
# Clone
git clone https://github.com/mysterion04/clean-my-mac.git
cd clean-my-mac

# Build (Debug)
xcodebuild \
  -project CleanMyMac.xcodeproj \
  -scheme CleanMyMac \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

# The .app will be in:
# build/Build/Products/Debug/CleanMyMac.app
```

---

## Stack

```
  ┌────────────────────────────────────────────────────┐
  │  Language     Swift 5.9                            │
  │  UI           SwiftUI + Swift Charts               │
  │  Architecture MVVM  (Model → Service → VM → View)  │
  │  Concurrency  async/await · actors · TaskGroup     │
  │  Target       macOS 14+ (Sonoma)                   │
  │  CI           GitHub Actions · macos-14-arm64      │
  └────────────────────────────────────────────────────┘
```

---

## Architecture

```
  CleanMyMac/
  ├── App/                    entry point + root view
  ├── Views/
  │   ├── Sidebar/            navigation sidebar
  │   ├── Screens/            one view per feature
  │   └── SharedComponents    reusable UI primitives
  ├── ViewModels/             @MainActor ObservableObjects
  ├── Services/               business logic (actors)
  ├── Models/                 plain Swift structs
  └── Utilities/              PathConstants, FormattingUtils
```

---

## Contributing

PRs welcome. Open an issue first for big changes.

---

## License

MIT — use it, fork it, ship it, do whatever.
