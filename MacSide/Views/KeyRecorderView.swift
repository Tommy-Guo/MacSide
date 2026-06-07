import SwiftUI
import AppKit

struct KeyRecorderView: NSViewRepresentable {
    @Binding var shortcut: HotKey

    func makeNSView(context: Context) -> KeyRecorderNSView {
        let view = KeyRecorderNSView()
        view.onShortcutRecorded = { newShortcut in
            shortcut = newShortcut
        }
        return view
    }

    func updateNSView(_ nsView: KeyRecorderNSView, context: Context) {
        nsView.currentShortcut = shortcut
        nsView.needsDisplay = true
    }
}

final class KeyRecorderNSView: NSView {
    var onShortcutRecorded: ((HotKey) -> Void)?
    var currentShortcut: HotKey = .empty
    var isRecording = false

    private let cornerRadius: CGFloat = 6
    private let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .medium)

    override var acceptsFirstResponder: Bool { true }
    override var intrinsicContentSize: NSSize { NSSize(width: 140, height: 28) }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        isRecording = true
        needsDisplay = true
    }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result { isRecording = true; needsDisplay = true }
        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result { isRecording = false; needsDisplay = true }
        return result
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else { super.keyDown(with: event); return }

        // Escape cancels recording without changing shortcut
        if event.keyCode == 53 {
            isRecording = false
            window?.makeFirstResponder(nil)
            needsDisplay = true
            return
        }

        // Delete/backspace clears the shortcut
        if event.keyCode == 51 || event.keyCode == 117 {
            currentShortcut = .empty
            onShortcutRecorded?(.empty)
            isRecording = false
            window?.makeFirstResponder(nil)
            needsDisplay = true
            return
        }

        let modifiers = UInt64(event.modifierFlags
            .intersection([.command, .shift, .option, .control])
            .rawValue)

        let new = HotKey(modifierFlags: modifiers, keyCode: event.keyCode)
        currentShortcut = new
        onShortcutRecorded?(new)
        isRecording = false
        window?.makeFirstResponder(nil)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let bounds = self.bounds

        // Background
        let bg: NSColor = isRecording
            ? NSColor.controlAccentColor.withAlphaComponent(0.15)
            : NSColor.controlBackgroundColor

        let path = NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius)
        bg.setFill()
        path.fill()

        // Border
        let borderColor: NSColor = isRecording
            ? NSColor.controlAccentColor
            : NSColor.separatorColor
        borderColor.setStroke()
        path.lineWidth = isRecording ? 1.5 : 1
        path.stroke()

        // Text
        let label: String
        if isRecording {
            label = "Type shortcut…"
        } else if currentShortcut.isEmpty {
            label = "Click to record"
        } else {
            label = currentShortcut.displayString
        }

        let color: NSColor = isRecording
            ? NSColor.controlAccentColor
            : (currentShortcut.isEmpty ? NSColor.placeholderTextColor : NSColor.labelColor)

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let str = NSAttributedString(string: label, attributes: attrs)
        let strSize = str.size()
        let x = (bounds.width - strSize.width) / 2
        let y = (bounds.height - strSize.height) / 2
        str.draw(at: NSPoint(x: x, y: y))
    }
}
