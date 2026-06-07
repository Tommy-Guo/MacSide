import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var hidManager: HIDManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "computermouse.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 1) {
                    Text("MacSide")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Extra button remapping")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: $hidManager.isEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            if !hidManager.hasAccessibilityPermission {
                permissionBanner
            } else {
                statusSection
            }

            Divider()

            // Bottom actions
            VStack(spacing: 2) {
                if #available(macOS 14, *) {
                    SettingsLink {
                        Label("Open Settings…", systemImage: "gearshape")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(MenuButtonStyle())
                } else {
                    Button {
                        NotificationCenter.default.post(name: .init("com.macside.openSettings"), object: nil)
                    } label: {
                        Label("Open Settings…", systemImage: "gearshape")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(MenuButtonStyle())
                }

                Divider().padding(.vertical, 2)

                Button {
                    NSApp.terminate(nil)
                } label: {
                    Label("Quit MacSide", systemImage: "power")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(MenuButtonStyle())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .frame(width: 280)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Active profile
            let active = profileManager.activeProfile()
            HStack(spacing: 8) {
                Image(systemName: active.isGlobal ? "globe" : "app.badge")
                    .font(.system(size: 12))
                    .foregroundColor(active.isGlobal ? .accentColor : .orange)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Active Profile")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(active.name)
                        .font(.system(size: 13, weight: .medium))
                }
                Spacer()
                Text("\(active.mappings.count) button\(active.mappings.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))

            // Quick mapping summary
            if !active.mappings.isEmpty {
                VStack(spacing: 4) {
                    ForEach(active.mappings.prefix(4)) { mapping in
                        HStack(spacing: 8) {
                            Text(mapping.buttonLabel)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 4))

                            Image(systemName: "arrow.right")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)

                            Image(systemName: mapping.action.symbolName)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .frame(width: 14)

                            Text(mapping.action.displayName)
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Spacer()
                        }
                    }
                    if active.mappings.count > 4 {
                        Text("+ \(active.mappings.count - 4) more…")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    private var permissionBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Accessibility Required")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Needed to intercept extra mouse buttons.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            #if DEBUG
            if hidManager.isDebuggerAttached {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "ant.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                        .padding(.top, 1)
                    Text("Xcode debugger detected — macOS blocks accessibility when attached. Edit Scheme → Run → Info → uncheck **\"Debug executable\"**, then relaunch.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }
            #endif

            if !hidManager.isDebuggerAttached {
                Text("Click **Grant Access** to open System Settings. Toggle MacSide **ON**, then click **Recheck**.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("If the toggle is already ON: turn it **off** then back **on**, then click **Recheck**.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Grant Access…") {
                    hidManager.requestPermissions()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            Button("Recheck") {
                hidManager.start()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Menu Button Style

struct MenuButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13))
            .foregroundColor(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isPressed
                          ? Color.accentColor.opacity(0.2)
                          : (isHovered ? Color.primary.opacity(0.07) : .clear))
            )
            .onHover { isHovered = $0 }
    }
}
