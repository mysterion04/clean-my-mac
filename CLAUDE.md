# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

Since Xcode is not installed locally, builds run via GitHub Actions on push to `main`. The workflow is at `.github/workflows/build.yml`.

To build or test locally if Xcode is available:

```bash
# Build
xcodebuild \
  -project CleanMyMac.xcodeproj \
  -scheme CleanMyMac \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build

# Run tests
xcodebuild \
  -project CleanMyMac.xcodeproj \
  -scheme CleanMyMacTests \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  test

# Run a single test class
xcodebuild \
  -project CleanMyMac.xcodeproj \
  -scheme CleanMyMacTests \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_ALLOWED=NO \
  -only-testing:CleanMyMacTests/YourTestClassName \
  test
```

## Architecture

The app follows **MVVM** with SwiftUI. Each feature module has: `Model → Service → ViewModel → View`.

### Navigation

`SidebarItem` (enum in `SidebarView.swift`) is the single source of truth for navigation. `MainView` switches the detail pane based on the selected `SidebarItem`. Adding a new feature requires adding a case to `SidebarItem` and a corresponding branch in `MainView`.

### Concurrency Model

- `FileSystemService` is a Swift **`actor`** — all file I/O must go through it using `await`. Never call `FileManager` directly from views or view models.
- `PermissionService` is `@MainActor` and injected app-wide via `.environmentObject`. Access it in views with `@EnvironmentObject var permissionService: PermissionService`.
- ViewModels are `@MainActor` classes with `@Published` properties. Long-running work is wrapped in `Task { }` blocks.

### Shared Infrastructure

- `FileSystemService` (`Services/`) — all file I/O, size calculation, directory enumeration, disk info, trash operations.
- `PathConstants` (`Utilities/`) — all hardcoded file system paths. Add new paths here rather than inline.
- `FormattingUtils` (`Utilities/`) — byte formatting (`formatBytes`). Use for all size display.
- `SharedComponents.swift` (`Views/`) — reusable UI: `ToolbarHeader`, `EmptyStateView`, `ScanningProgressView`, `SummaryBar`, `SearchBar`, `Color(hex:)` extension.

### UI Conventions

- Dark-mode only. Base background: `Color(hex: "111111")`, sidebar: `Color(hex: "1A1A1A")`, toolbar: `Color(hex: "161616")`.
- Each feature screen follows the same layout: `ToolbarHeader` at top → list/content area → `SummaryBar` at bottom when items are selected.
- Each `SidebarItem` has an `accentColor` — use it consistently for icons and tinted buttons within that feature's screen.
