import Foundation
import CoreGraphics
import AppKit

enum SystemAction: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case missionControl = "Mission Control"
    case appExpose = "App Exposé"
    case showDesktop = "Show Desktop"
    case launchpad = "Launchpad"
    case volumeUp = "Volume Up"
    case volumeDown = "Volume Down"
    case mute = "Mute / Unmute"
    case brightnessUp = "Brightness Up"
    case brightnessDown = "Brightness Down"
    case playPause = "Play / Pause"
    case nextTrack = "Next Track"
    case previousTrack = "Previous Track"
    case screenshot = "Screenshot"
    case spotlight = "Spotlight Search"
    case notificationCenter = "Notification Center"
    case browserBack = "Browser Back"
    case browserForward = "Browser Forward"

    var symbolName: String {
        switch self {
        case .missionControl: return "square.3.layers.3d.top.filled"
        case .appExpose: return "square.stack"
        case .showDesktop: return "desktopcomputer"
        case .launchpad: return "square.grid.3x3.fill"
        case .volumeUp: return "speaker.wave.3.fill"
        case .volumeDown: return "speaker.wave.1.fill"
        case .mute: return "speaker.slash.fill"
        case .brightnessUp: return "sun.max.fill"
        case .brightnessDown: return "sun.min.fill"
        case .playPause: return "playpause.fill"
        case .nextTrack: return "forward.fill"
        case .previousTrack: return "backward.fill"
        case .screenshot: return "camera.viewfinder"
        case .spotlight: return "magnifyingglass"
        case .notificationCenter: return "bell.fill"
        case .browserBack: return "chevron.left"
        case .browserForward: return "chevron.right"
        }
    }
}

struct HotKey: Codable, Hashable, Equatable {
    var modifierFlags: UInt64
    var keyCode: UInt16

    var displayString: String {
        var result = ""
        let flags = CGEventFlags(rawValue: modifierFlags)
        if flags.contains(.maskControl) { result += "⌃" }
        if flags.contains(.maskAlternate) { result += "⌥" }
        if flags.contains(.maskShift) { result += "⇧" }
        if flags.contains(.maskCommand) { result += "⌘" }
        result += keyCodeToGlyph(keyCode)
        return result
    }

    static let empty = HotKey(modifierFlags: 0, keyCode: 0)

    var isEmpty: Bool { modifierFlags == 0 && keyCode == 0 }
}

private func keyCodeToGlyph(_ keyCode: UInt16) -> String {
    let map: [UInt16: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
        8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
        16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
        23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
        30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "↩",
        37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",",
        44: "/", 45: "N", 46: "M", 47: ".", 48: "⇥", 49: "Space", 50: "`",
        51: "⌫", 53: "⎋", 56: "⇧", 57: "⇪", 58: "⌥", 59: "⌃",
        60: "⇧", 61: "⌥", 62: "⌃", 63: "fn",
        96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9",
        103: "F11", 105: "F13", 107: "F14", 109: "F10", 111: "F12",
        113: "F15", 114: "Ins", 115: "↖", 116: "⇞", 117: "⌦", 118: "F4",
        119: "↘", 120: "F2", 121: "⇟", 122: "F1", 123: "←", 124: "→",
        125: "↓", 126: "↑"
    ]
    return map[keyCode] ?? "?\(keyCode)"
}

enum ButtonAction: Codable, Hashable, Equatable {
    case none
    case keyboardShortcut(HotKey)
    case systemAction(SystemAction)
    case launchApp(bundleID: String, name: String)
    case openURL(String)
    case scrollUp
    case scrollDown

    var displayName: String {
        switch self {
        case .none: return "No Action"
        case .keyboardShortcut(let s): return s.isEmpty ? "Record shortcut…" : s.displayString
        case .systemAction(let a): return a.rawValue
        case .launchApp(_, let name): return "Open \(name)"
        case .openURL(let url): return url.isEmpty ? "Enter URL…" : url
        case .scrollUp: return "Scroll Up"
        case .scrollDown: return "Scroll Down"
        }
    }

    var symbolName: String {
        switch self {
        case .none: return "minus"
        case .keyboardShortcut: return "keyboard"
        case .systemAction(let a): return a.symbolName
        case .launchApp: return "app.badge"
        case .openURL: return "link"
        case .scrollUp: return "arrow.up"
        case .scrollDown: return "arrow.down"
        }
    }

    var actionType: ActionType {
        switch self {
        case .none: return .none
        case .keyboardShortcut: return .keyboardShortcut
        case .systemAction: return .systemAction
        case .launchApp: return .launchApp
        case .openURL: return .openURL
        case .scrollUp: return .scroll
        case .scrollDown: return .scroll
        }
    }

    enum ActionType: String, CaseIterable, Identifiable {
        var id: String { rawValue }
        case none = "No Action"
        case keyboardShortcut = "Keyboard Shortcut"
        case systemAction = "System Action"
        case launchApp = "Launch App"
        case openURL = "Open URL"
        case scroll = "Scroll"
    }
}
