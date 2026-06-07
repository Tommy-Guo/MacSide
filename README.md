# MacSide

MacSide is a lightweight native macOS utility that intercepts extra mouse buttons (M3–M7) and lets you remap them to keyboard shortcuts, system actions, app launches, URLs, or scroll — something macOS doesn't do out of the box.

Built for Apple Silicon. No subscription, no telemetry, no App Store required.

---

## Features

- **Remap extra buttons** — M3 (middle click), M4, M5, M6, M7 and beyond
- **Multiple action types per button:**
  - Keyboard shortcut (any key combo you record)
  - System action (Mission Control, App Exposé, Launchpad, volume, brightness, media keys, screenshot, Spotlight, Notification Center, browser back/forward)
  - Launch an app
  - Open a URL
  - Scroll up / scroll down
- **Per-app profiles** — different mappings activate automatically based on the frontmost app
- **Global fallback profile** — applies when no per-app profile matches
- **Menu bar icon** — click to view status, toggle remapping on/off, open settings
- **Launch at login** — optional, one toggle in Settings
- **Runs silently** — no Dock icon, lives entirely in the menu bar

---

## Requirements

- macOS 13 Ventura or later
- Apple Silicon Mac (M1/M2/M3/M4 series)
- Accessibility permission (required to intercept mouse events)

---

## Installation

### Option A — Download the DMG

1. Download `MacSide-1.0.dmg` from the [Releases](../../releases) page
2. Open the DMG and drag **MacSide.app** to your Applications folder
3. Right-click the app → **Open** → **Open** (required once, since the app is not notarized)
4. Grant Accessibility permission when prompted

### Option B — Build from source

```bash
git clone https://github.com/Tommy-Guo/MacSide.git
cd MacSide/MacSide
open MacSide.xcodeproj
```

Select the **MacSide** scheme, set destination to **My Mac**, and hit **Run** (⌘R).

> No third-party dependencies. No Swift Package Manager setup needed.

---

## Permissions

MacSide requires **Accessibility** access to intercept mouse button events system-wide. When you first launch the app you will be prompted automatically.

If you need to re-grant it:

**System Settings → Privacy & Security → Accessibility → enable MacSide**

---

## Usage

1. Click the mouse icon in the menu bar to open the panel
2. Open **Settings** to create and manage profiles
3. Add a profile for a specific app, or edit the **Global** profile for a catch-all
4. For each button, choose an action type and configure it
5. Toggle remapping on/off anytime from the menu bar panel

---

## Project Structure

```
MacSide/
├── MacSideApp.swift          # App entry point
├── AppDelegate.swift         # Menu bar icon, popover, lifecycle
├── MacSide.entitlements
├── Info.plist
├── Assets.xcassets/
├── Models/
│   ├── ButtonAction.swift    # Action types and HotKey model
│   └── Profile.swift         # Profile and ButtonMapping model
├── Services/
│   ├── HIDManager.swift      # CGEvent tap — intercepts mouse buttons
│   ├── ActionExecutor.swift  # Fires keyboard events / system actions
│   ├── ProfileManager.swift  # Persists and resolves profiles
│   └── ActiveAppMonitor.swift# Watches frontmost app for per-app profiles
└── Views/
    ├── MenuBarView.swift      # Popover content
    ├── SettingsView.swift     # Settings window
    ├── ProfileEditorView.swift
    ├── MappingRowView.swift
    └── KeyRecorderView.swift  # Hotkey recorder
```

---

## Building a Release DMG

```bash
chmod +x release.sh
./release.sh
```

This produces `MacSide-1.0.dmg` in the project root. The app is ad-hoc signed — users will need to right-click → Open on first launch.

---

## AI Disclaimer

Parts of this project was created with the use of AI.

---


## License

MIT. See [LICENSE](LICENSE) for details.
