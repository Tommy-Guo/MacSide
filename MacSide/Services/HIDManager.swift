import Cocoa
import CoreGraphics
import ApplicationServices

final class HIDManager: ObservableObject {
    static let shared = HIDManager()

    @Published var isEnabled: Bool = true {
        didSet { isEnabled ? enableTap() : disableTap() }
    }
    @Published var hasAccessibilityPermission: Bool = false

    var onButtonEvent: ((Int, Bool) -> Void)?
    var suppressedButtons: Set<Int> = []

    var onDetectNextButton: ((Int) -> Void)? {
        didSet {
            if onDetectNextButton != nil, eventTap == nil { start() }
        }
    }

    private(set) var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private init() {}

    // MARK: - Permissions

    /// Only shown during development — release builds never run under a debugger.
    var isDebuggerAttached: Bool {
        #if DEBUG
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
        return info.kp_proc.p_flag & P_TRACED != 0
        #else
        return false
        #endif
    }

    @discardableResult
    func refreshPermissionState() -> Bool {
        let trusted = AXIsProcessTrusted()
        hasAccessibilityPermission = trusted
        return trusted
    }

    func requestPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Tap lifecycle

    func start() {
        guard refreshPermissionState() else { return }
        guard eventTap == nil else { return }

        let mask: CGEventMask =
            (1 << CGEventType.otherMouseDown.rawValue) |
            (1 << CGEventType.otherMouseUp.rawValue)

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: HIDManager.tapCallback,
            userInfo: selfPtr
        ) else {
            hasAccessibilityPermission = false
            return
        }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: isEnabled)
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
            eventTap = nil
            runLoopSource = nil
        }
    }

    private func enableTap() {
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) } else { start() }
    }

    private func disableTap() {
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: false) }
    }

    // MARK: - Event handling

    func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type.rawValue == 0xFFFFFFFE || type.rawValue == 0xFFFFFFFF {
            if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
            return nil
        }

        guard type == .otherMouseDown || type == .otherMouseUp else {
            return Unmanaged.passRetained(event)
        }

        let buttonNumber = Int(event.getIntegerValueField(.mouseEventButtonNumber))
        guard buttonNumber >= 2 else { return Unmanaged.passRetained(event) }

        if type == .otherMouseDown, let detect = onDetectNextButton {
            onDetectNextButton = nil
            DispatchQueue.main.async { detect(buttonNumber) }
            return nil
        }

        let isPressed = (type == .otherMouseDown)
        let shouldSuppress = suppressedButtons.contains(buttonNumber)
        if shouldSuppress { onButtonEvent?(buttonNumber, isPressed) }
        return shouldSuppress ? nil : Unmanaged.passRetained(event)
    }

    private static let tapCallback: CGEventTapCallBack = { proxy, type, event, context in
        guard let context = context else { return Unmanaged.passRetained(event) }
        let manager = Unmanaged<HIDManager>.fromOpaque(context).takeUnretainedValue()
        return manager.handleEvent(proxy: proxy, type: type, event: event)
    }
}
