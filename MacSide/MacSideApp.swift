import SwiftUI

@main
struct MacSideApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(ProfileManager.shared)
                .environmentObject(HIDManager.shared)
        }
    }
}
