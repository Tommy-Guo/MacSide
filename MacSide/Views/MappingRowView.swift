import SwiftUI
import AppKit

struct MappingRowView: View {
    @Binding var mapping: ButtonMapping
    var onDelete: () -> Void

    @State private var showingActionPicker = false
    @State private var isBadgeFlashing = false
    @State private var selectedActionType: ButtonAction.ActionType = .none
    @State private var pendingShortcut: HotKey = .empty
    @State private var pendingSystemAction: SystemAction = .missionControl
    @State private var pendingAppBundleID: String = ""
    @State private var pendingAppName: String = ""
    @State private var pendingURL: String = ""
    @State private var pendingScrollDirection: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            // Badge — tapping flashes it and opens the picker
            Button {
                flashBadge()
                syncStateFromMapping()
                showingActionPicker = true
            } label: {
                Text(mapping.buttonLabel)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(badgeColor, in: RoundedRectangle(cornerRadius: 6))
                    .frame(width: 42)
                    .scaleEffect(isBadgeFlashing ? 1.28 : 1.0)
                    .shadow(color: badgeColor.opacity(isBadgeFlashing ? 0.55 : 0),
                            radius: isBadgeFlashing ? 8 : 0)
            }
            .buttonStyle(.plain)

            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundColor(.secondary)

            // Action picker trigger
            Button {
                syncStateFromMapping()
                showingActionPicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: mapping.action.symbolName)
                        .font(.system(size: 12))
                        .foregroundColor(.accentColor)
                        .frame(width: 16)
                    Text(mapping.action.displayName)
                        .font(.system(size: 13))
                        .foregroundColor(mapping.action == .none ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(NSColor.separatorColor), lineWidth: 0.5))
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .opacity(0.7)
        }
        .padding(.vertical, 2)
        .sheet(isPresented: $showingActionPicker) {
            ActionPickerSheet(
                buttonLabel: mapping.buttonLabel,
                badgeColor: badgeColor,
                actionType: $selectedActionType,
                shortcut: $pendingShortcut,
                systemAction: $pendingSystemAction,
                appBundleID: $pendingAppBundleID,
                appName: $pendingAppName,
                url: $pendingURL,
                scrollUp: $pendingScrollDirection
            ) {
                applyPendingAction()
                showingActionPicker = false
            } onCancel: {
                showingActionPicker = false
            }
        }
    }

    private var badgeColor: Color {
        switch mapping.buttonNumber {
        case 2: return .gray
        case 3: return .blue
        case 4: return .purple
        case 5: return .orange
        default: return .teal
        }
    }

    private func flashBadge() {
        withAnimation(.spring(response: 0.14, dampingFraction: 0.38)) {
            isBadgeFlashing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.6)) {
                isBadgeFlashing = false
            }
        }
    }

    private func syncStateFromMapping() {
        selectedActionType = mapping.action.actionType
        switch mapping.action {
        case .keyboardShortcut(let s): pendingShortcut = s
        case .systemAction(let a):     pendingSystemAction = a
        case .launchApp(let bid, let name): pendingAppBundleID = bid; pendingAppName = name
        case .openURL(let url):        pendingURL = url
        case .scrollUp:                pendingScrollDirection = true
        case .scrollDown:              pendingScrollDirection = false
        default: break
        }
    }

    private func applyPendingAction() {
        switch selectedActionType {
        case .none:             mapping.action = .none
        case .keyboardShortcut: mapping.action = .keyboardShortcut(pendingShortcut)
        case .systemAction:     mapping.action = .systemAction(pendingSystemAction)
        case .launchApp:        mapping.action = .launchApp(bundleID: pendingAppBundleID, name: pendingAppName)
        case .openURL:          mapping.action = .openURL(pendingURL)
        case .scroll:           mapping.action = pendingScrollDirection ? .scrollUp : .scrollDown
        }
    }
}

// MARK: - Action Picker Sheet

struct ActionPickerSheet: View {
    let buttonLabel: String
    let badgeColor: Color

    @Binding var actionType: ButtonAction.ActionType
    @Binding var shortcut: HotKey
    @Binding var systemAction: SystemAction
    @Binding var appBundleID: String
    @Binding var appName: String
    @Binding var url: String
    @Binding var scrollUp: Bool

    var onConfirm: () -> Void
    var onCancel: () -> Void

    // Icon for each action type card
    private func icon(for type: ButtonAction.ActionType) -> String {
        switch type {
        case .none:             return "minus.circle"
        case .keyboardShortcut: return "keyboard"
        case .systemAction:     return "gearshape.fill"
        case .launchApp:        return "app.badge"
        case .openURL:          return "link"
        case .scroll:           return "arrow.up.arrow.down"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Text(buttonLabel)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(badgeColor, in: RoundedRectangle(cornerRadius: 6))

                Text("Choose Action")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Action type grid — 3 columns × 2 rows
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Action Type", systemImage: "bolt.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                            spacing: 8
                        ) {
                            ForEach(ButtonAction.ActionType.allCases) { type in
                                let selected = actionType == type
                                Button { actionType = type } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: icon(for: type))
                                            .font(.system(size: 20))
                                            .frame(height: 24)
                                        Text(type.rawValue)
                                            .font(.system(size: 11, weight: .medium))
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 8)
                                    .background(
                                        selected
                                            ? Color.accentColor
                                            : Color(NSColor.controlBackgroundColor),
                                        in: RoundedRectangle(cornerRadius: 10)
                                    )
                                    .foregroundColor(selected ? .white : .primary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selected ? Color.clear : Color(NSColor.separatorColor),
                                                    lineWidth: 0.5)
                                    )
                                }
                                .buttonStyle(.plain)
                                .animation(.easeInOut(duration: 0.12), value: selected)
                            }
                        }
                    }

                    // Detail section
                    if actionType != .none {
                        Divider()
                        detailSection
                    }
                }
                .padding(20)
            }

            Divider()

            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Apply", action: onConfirm)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
            .padding(16)
        }
        .frame(width: 520)
        .background(Color(NSColor.windowBackgroundColor))
    }

    @ViewBuilder
    private var detailSection: some View {
        switch actionType {
        case .none:
            EmptyView()

        case .keyboardShortcut:
            VStack(alignment: .leading, spacing: 8) {
                Label("Shortcut", systemImage: "keyboard")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                HStack(spacing: 12) {
                    KeyRecorderView(shortcut: $shortcut)
                        .frame(height: 32)
                    if !shortcut.isEmpty {
                        Text(shortcut.displayString)
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundColor(.accentColor)
                    }
                    Spacer()
                }
                Text("Click the field and press your shortcut. Press Delete to clear.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        case .systemAction:
            VStack(alignment: .leading, spacing: 8) {
                Label("System Action", systemImage: "gearshape.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                Picker("", selection: $systemAction) {
                    ForEach(SystemAction.allCases) { action in
                        Label(action.rawValue, systemImage: action.symbolName).tag(action)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .launchApp:
            VStack(alignment: .leading, spacing: 8) {
                Label("App", systemImage: "app.badge")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if appName.isEmpty {
                            Text("No app selected")
                                .foregroundColor(.secondary)
                        } else {
                            Text(appName).fontWeight(.medium)
                            Text(appBundleID).font(.caption).foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Button("Choose…") { chooseApp() }
                        .buttonStyle(.bordered)
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            }

        case .openURL:
            VStack(alignment: .leading, spacing: 8) {
                Label("URL", systemImage: "link")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                TextField("https://example.com", text: $url)
                    .textFieldStyle(.roundedBorder)
            }

        case .scroll:
            VStack(alignment: .leading, spacing: 8) {
                Label("Direction", systemImage: "arrow.up.arrow.down")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                Picker("", selection: $scrollUp) {
                    Label("Scroll Up", systemImage: "arrow.up").tag(true)
                    Label("Scroll Down", systemImage: "arrow.down").tag(false)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 200)
            }
        }
    }

    private func chooseApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            let bundle = Bundle(url: url)
            appBundleID = bundle?.bundleIdentifier ?? url.deletingPathExtension().lastPathComponent
            appName = url.deletingPathExtension().lastPathComponent
        }
    }
}
