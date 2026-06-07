import AppKit
import Combine

final class ActiveAppMonitor: ObservableObject {
    static let shared = ActiveAppMonitor()

    @Published var frontmostBundleID: String? = nil
    @Published var frontmostAppName: String? = nil

    private var observer: Any?

    private init() {
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            self?.frontmostBundleID = app?.bundleIdentifier
            self?.frontmostAppName = app?.localizedName
        }

        // Set initial value
        let app = NSWorkspace.shared.frontmostApplication
        frontmostBundleID = app?.bundleIdentifier
        frontmostAppName = app?.localizedName
    }

    deinit {
        if let observer { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
    }
}
