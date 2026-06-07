import Cocoa
import CoreGraphics

final class ActionExecutor {
    static let shared = ActionExecutor()
    private init() {}

    func execute(_ action: ButtonAction, isPressed: Bool) {
        guard isPressed else {
            // Key-up for keyboard shortcuts
            if case .keyboardShortcut(let shortcut) = action {
                postKeyEvent(shortcut: shortcut, keyDown: false)
            }
            return
        }

        switch action {
        case .none:
            break
        case .keyboardShortcut(let shortcut):
            postKeyEvent(shortcut: shortcut, keyDown: true)
        case .systemAction(let sysAction):
            executeSystemAction(sysAction)
        case .launchApp(let bundleID, _):
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                NSWorkspace.shared.openApplication(at: url,
                                                   configuration: NSWorkspace.OpenConfiguration())
            }
        case .openURL(let urlString):
            if let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        case .scrollUp:
            postScrollEvent(lines: -5)
        case .scrollDown:
            postScrollEvent(lines: 5)
        }
    }

    // MARK: - Keyboard

    private func postKeyEvent(shortcut: HotKey, keyDown: Bool) {
        guard !shortcut.isEmpty else { return }
        let src = CGEventSource(stateID: .hidSystemState)
        guard let event = CGEvent(keyboardEventSource: src, virtualKey: shortcut.keyCode, keyDown: keyDown) else { return }
        event.flags = CGEventFlags(rawValue: shortcut.modifierFlags)
        event.post(tap: .cghidEventTap)
    }

    // MARK: - System Actions

    private func executeSystemAction(_ action: SystemAction) {
        switch action {
        case .missionControl:
            postKeyPress(keyCode: 160)   // F9 / Mission Control key
        case .appExpose:
            postKeyPress(keyCode: 101)   // F10 / App Exposé
        case .showDesktop:
            postKeyPress(keyCode: 103)   // F11 / Show Desktop
        case .launchpad:
            postKeyPress(keyCode: 131)   // Launchpad key
        case .volumeUp:
            postMediaKey(keyType: 0)     // NX_KEYTYPE_SOUND_UP
        case .volumeDown:
            postMediaKey(keyType: 1)     // NX_KEYTYPE_SOUND_DOWN
        case .mute:
            postMediaKey(keyType: 7)     // NX_KEYTYPE_MUTE
        case .brightnessUp:
            postMediaKey(keyType: 2)     // NX_KEYTYPE_BRIGHTNESS_UP
        case .brightnessDown:
            postMediaKey(keyType: 3)     // NX_KEYTYPE_BRIGHTNESS_DOWN
        case .playPause:
            postMediaKey(keyType: 16)    // NX_KEYTYPE_PLAY
        case .nextTrack:
            postMediaKey(keyType: 17)    // NX_KEYTYPE_NEXT
        case .previousTrack:
            postMediaKey(keyType: 18)    // NX_KEYTYPE_PREVIOUS
        case .screenshot:
            postShortcut(keyCode: 20, flags: [.maskCommand, .maskShift])   // ⌘⇧4
        case .spotlight:
            postShortcut(keyCode: 49, flags: [.maskCommand])               // ⌘Space
        case .notificationCenter:
            postShortcut(keyCode: 124, flags: [.maskCommand, .maskAlternate, .maskControl]) // best effort
        case .browserBack:
            postShortcut(keyCode: 123, flags: [.maskCommand])  // ⌘←
        case .browserForward:
            postShortcut(keyCode: 124, flags: [.maskCommand])  // ⌘→
        }
    }

    private func postKeyPress(keyCode: CGKeyCode) {
        let src = CGEventSource(stateID: .hidSystemState)
        CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true)?.post(tap: .cghidEventTap)
        CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false)?.post(tap: .cghidEventTap)
    }

    private func postShortcut(keyCode: CGKeyCode, flags: CGEventFlags) {
        let src = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true)
        down?.flags = flags
        down?.post(tap: .cghidEventTap)
        let up = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false)
        up?.flags = flags
        up?.post(tap: .cghidEventTap)
    }

    private func postMediaKey(keyType: Int) {
        let flagsDown = 0xa00
        let flagsUp   = 0xb00
        let data1Down = (keyType << 16) | flagsDown
        let data1Up   = (keyType << 16) | flagsUp

        func makeEvent(data1: Int, flags: NSEvent.ModifierFlags) -> NSEvent? {
            NSEvent.otherEvent(
                with: .systemDefined,
                location: .zero,
                modifierFlags: flags,
                timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: 0,
                context: nil,
                subtype: 8,
                data1: data1,
                data2: -1
            )
        }

        makeEvent(data1: data1Down, flags: NSEvent.ModifierFlags(rawValue: UInt(flagsDown)))?.cgEvent?.post(tap: .cghidEventTap)
        makeEvent(data1: data1Up,   flags: NSEvent.ModifierFlags(rawValue: UInt(flagsUp)))?.cgEvent?.post(tap: .cghidEventTap)
    }

    // MARK: - Scroll

    private func postScrollEvent(lines: Int32) {
        CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1, wheel1: lines, wheel2: 0, wheel3: 0)?
            .post(tap: .cghidEventTap)
    }
}
