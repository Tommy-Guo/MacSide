import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var hidManager: HIDManager
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true
    @State private var showingAddAppSheet = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if let id = profileManager.selectedProfileID {
                ProfileEditorView(profileID: id)
                    .environmentObject(profileManager)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("No Profile Selected")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        .sheet(isPresented: $showingAddAppSheet) {
            AddAppProfileSheet { bundleID, name in
                let profile = Profile(name: name, bundleIdentifier: bundleID)
                profileManager.addProfile(profile)
                showingAddAppSheet = false
            } onCancel: {
                showingAddAppSheet = false
            }
        }
        .frame(minWidth: 700, minHeight: 480)
    }

    private var sidebar: some View {
        List(selection: $profileManager.selectedProfileID) {
            Section("Profiles") {
                ForEach(profileManager.profiles) { profile in
                    ProfileRowView(profile: profile,
                                   isActive: isActive(profile))
                        .tag(profile.id)
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 8) {
                    Button {
                        showingAddAppSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderless)
                    .help("Add App Profile")

                    Button {
                        if let id = profileManager.selectedProfileID {
                            profileManager.deleteProfile(id: id)
                        }
                    } label: {
                        Image(systemName: "minus")
                    }
                    .buttonStyle(.borderless)
                    .disabled(selectedProfileIsGlobal)
                    .help("Remove Profile")

                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)

                Divider()

                HStack(spacing: 8) {
                    Image(systemName: "menubar.rectangle")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Menu bar icon")
                            .font(.system(size: 12))
                        if !showMenuBarIcon {
                            Text("Re-launch MacSide to restore")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                        }
                    }
                    Spacer()
                    Toggle("", isOn: $showMenuBarIcon)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .labelsHidden()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)

                Divider()

                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("Launch at login")
                        .font(.system(size: 12))
                    Spacer()
                    Toggle("", isOn: launchAtLoginBinding)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .labelsHidden()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
        }
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { SMAppService.mainApp.status == .enabled },
            set: { enable in
                do {
                    if enable {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {}
            }
        )
    }

    private var selectedProfileIsGlobal: Bool {
        guard let id = profileManager.selectedProfileID else { return true }
        return profileManager.profiles.first { $0.id == id }?.isGlobal ?? true
    }

    private func isActive(_ profile: Profile) -> Bool {
        profileManager.activeProfile().id == profile.id
    }
}

// MARK: - Profile Sidebar Row

struct ProfileRowView: View {
    let profile: Profile
    let isActive: Bool

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 28, height: 28)
                Image(systemName: profile.isGlobal ? "globe" : "app.badge")
                    .font(.system(size: 13))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(profile.name)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isActive {
                Circle()
                    .fill(Color.green)
                    .frame(width: 7, height: 7)
            }
        }
        .padding(.vertical, 2)
    }

    private var iconBackground: Color {
        profile.isGlobal ? Color.accentColor.opacity(0.12) : Color.orange.opacity(0.12)
    }

    private var iconColor: Color {
        profile.isGlobal ? .accentColor : .orange
    }

    private var subtitle: String {
        let count = profile.mappings.count
        if profile.isGlobal {
            return count == 0 ? "No mappings" : "\(count) mapping\(count == 1 ? "" : "s")"
        }
        return profile.bundleIdentifier ?? ""
    }
}

// MARK: - Add App Profile Sheet

struct AddAppProfileSheet: View {
    var onAdd: (String, String) -> Void
    var onCancel: () -> Void

    @State private var selectedBundleID: String = ""
    @State private var selectedName: String = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add App Profile")
                    .font(.headline)
                Spacer()
            }
            .padding([.horizontal, .top], 20)
            .padding(.bottom, 16)

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                Text("Create a custom button mapping for a specific app.\nWhen this app is frontmost, these mappings override the Global profile.")
                    .font(.callout)
                    .foregroundColor(.secondary)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if selectedName.isEmpty {
                            Text("No app selected")
                                .foregroundColor(.secondary)
                        } else {
                            Text(selectedName).fontWeight(.medium)
                            Text(selectedBundleID).font(.caption).foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Button("Choose App…") { chooseApp() }
                        .buttonStyle(.bordered)
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(20)

            Divider()

            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Add Profile") { onAdd(selectedBundleID, selectedName) }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedBundleID.isEmpty)
            }
            .padding(16)
        }
        .frame(width: 380)
    }

    private func chooseApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            let bundle = Bundle(url: url)
            selectedBundleID = bundle?.bundleIdentifier ?? url.deletingPathExtension().lastPathComponent
            selectedName = url.deletingPathExtension().lastPathComponent
        }
    }
}
