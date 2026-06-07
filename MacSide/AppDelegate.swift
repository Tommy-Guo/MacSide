import Cocoa
import SwiftUI
import Combine

private let kReopenNotification = "com.macside.app.reopen"
private let kOpenSettings       = "com.macside.openSettings"

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var permissionTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Single-instance: if MacSide is already running, signal it to restore
        // its menu bar icon and quit this copy.
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
        if !others.isEmpty {
            DistributedNotificationCenter.default().postNotificationName(
                .init(kReopenNotification), object: nil, deliverImmediately: true
            )
            // Brief pause so the notification reaches the live instance before we quit.
            Thread.sleep(forTimeInterval: 0.15)
            NSApp.terminate(nil)
            return
        }

        // Fresh launch always shows the menu bar icon.
        UserDefaults.standard.set(true, forKey: "showMenuBarIcon")

        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(handleReopen),
            name: .init(kReopenNotification), object: nil,
            suspensionBehavior: .deliverImmediately
        )

        NotificationCenter.default.addObserver(
            self, selector: #selector(handleOpenSettings),
            name: .init(kOpenSettings), object: nil
        )

        NotificationCenter.default.addObserver(
            self, selector: #selector(userDefaultsDidChange),
            name: UserDefaults.didChangeNotification, object: nil
        )

        NSApp.setActivationPolicy(.accessory)

        let hid = HIDManager.shared
        hid.onButtonEvent = { buttonNumber, isPressed in
            let profile = ProfileManager.shared.activeProfile()
            if let mapping = profile.mappings.first(where: { $0.buttonNumber == buttonNumber }) {
                ActionExecutor.shared.execute(mapping.action, isPressed: isPressed)
            }
        }
        hid.start()
        if !hid.hasAccessibilityPermission {
            hid.requestPermissions()
            startPermissionPolling()
        }

        buildStatusItem()

        // Keep the menu bar icon in sync with the enabled toggle.
        HIDManager.shared.$isEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                self?.statusItem?.button?.image = NSImage(
                    systemSymbolName: isEnabled ? "computermouse.fill" : "computermouse",
                    accessibilityDescription: "MacSide"
                )
            }
            .store(in: &cancellables)
    }

    // MARK: - Status item

    private func buildStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(
            systemSymbolName: HIDManager.shared.isEnabled ? "computermouse.fill" : "computermouse",
            accessibilityDescription: "MacSide"
        )
        item.button?.action = #selector(togglePopover)
        item.button?.target = self
        statusItem = item

        let content = MenuBarView()
            .environmentObject(ProfileManager.shared)
            .environmentObject(HIDManager.shared)
        let hosting = NSHostingController(rootView: content)
        hosting.sizingOptions = .preferredContentSize

        let pop = NSPopover()
        pop.contentViewController = hosting
        pop.behavior = .transient
        pop.animates = false
        popover = pop
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button else { return }
        if popover?.isShown == true {
            popover?.performClose(nil)
        } else {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Settings

    @objc private func handleOpenSettings() {
        popover?.performClose(nil)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Show / hide icon

    @objc private func userDefaultsDidChange() {
        let show = UserDefaults.standard.bool(forKey: "showMenuBarIcon")
        if show, statusItem == nil {
            buildStatusItem()
        } else if !show, let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
            popover = nil
        }
    }

    // MARK: - Misc

    @objc private func handleReopen() {
        UserDefaults.standard.set(true, forKey: "showMenuBarIcon")
        // Rebuild directly — don't rely on the didChangeNotification timing.
        DispatchQueue.main.async { [self] in
            if statusItem == nil { buildStatusItem() }
        }
    }

    private func startPermissionPolling() {
        permissionTimer?.invalidate()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] timer in
            let hid = HIDManager.shared
            if hid.eventTap == nil { hid.start() }
            if hid.hasAccessibilityPermission {
                timer.invalidate()
                self?.permissionTimer = nil
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
