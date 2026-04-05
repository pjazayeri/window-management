# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```sh
make app     # compile (release) + assemble WindowManager.app + ad-hoc sign
make run     # make app, then open it
make clean   # remove WindowManager.app and swift build artefacts
swift build  # fast debug build (no .app bundle produced)
```

The app requires **Accessibility permission** (System Settings → Privacy & Security → Accessibility). On first launch macOS shows the prompt automatically; hotkeys silently no-op until access is granted.

## Architecture

This is a Swift Package Manager executable (`Sources/WindowManager/`) that becomes a macOS menu-bar app when bundled via the `Makefile`.

### Data flow for a hotkey press

```
Carbon event loop
  └─ carbonEventHandler (@convention(c), HotKeyManager.swift)
       └─ hotkeyCallbacks[id]()           (registered closure)
            └─ WindowMover.moveFrontmost(to: SnapPosition)
                 ├─ focusedWindow()        AXUIElement of the frontmost window
                 ├─ ScreenUtils.screen(containing:)   which NSScreen holds it
                 ├─ ScreenUtils.axFrame(for:on:)       target CGRect in AX coords
                 └─ setFrame(of:to:)       AXUIElementSetAttributeValue ×2
```

### Key files

| File | Responsibility |
|---|---|
| `main.swift` | Entry point — creates `NSApplication`, sets `.accessory` activation policy |
| `AppDelegate.swift` | Menu-bar `NSStatusItem`, accessibility permission prompt |
| `HotKeyManager.swift` | Registers Carbon `RegisterEventHotKey` shortcuts; stores callbacks in file-scope dicts accessible from the `@convention(c)` handler |
| `ScreenUtils.swift` | Converts `NSScreen` visible frames → AX coordinates; calculates snap `CGRect` for every `SnapPosition`; finds which screen contains a window |
| `WindowMover.swift` | Reads the focused window via `AXUIElement`, calls `ScreenUtils`, writes position + size back via `AXUIElementSetAttributeValue` |

### Coordinate systems

macOS has two coordinate systems that must not be mixed:

- **NSScreen (bottom-left origin)** — used by `NSScreen.visibleFrame` for snap math.
- **AX / CGDisplay (top-left origin)** — required by `AXUIElementSetAttributeValue`.

Conversion (defined in `ScreenUtils.axFrame`):
```swift
axY = NSScreen.screens[0].frame.height - nsRect.maxY
```

All snap geometry is computed in NSScreen coords first, then converted to AX coords before being written to the window.

### Adding a new snap position

1. Add a case to `SnapPosition` in `ScreenUtils.swift`.
2. Add a `case` branch returning the target `NSRect` (then wrapped with `ax()`) in `ScreenUtils.axFrame(for:on:)`.
3. Register the hotkey in `HotKeyManager.registerAll()`.
