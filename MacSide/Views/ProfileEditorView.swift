import SwiftUI

struct ProfileEditorView: View {
    let profileID: UUID
    @EnvironmentObject var profileManager: ProfileManager

    @State private var isDetecting = false
    @State private var duplicateButtonNumber: Int? = nil

    private var profile: Profile? {
        profileManager.profiles.first { $0.id == profileID }
    }

    var body: some View {
        if let profile {
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    // Profile header
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(profile.isGlobal
                                      ? Color.accentColor.opacity(0.15)
                                      : Color.orange.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: profile.isGlobal ? "globe" : "app.badge")
                                .font(.system(size: 18))
                                .foregroundColor(profile.isGlobal ? .accentColor : .orange)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile.name)
                                .font(.title3.weight(.semibold))
                            Text(profile.isGlobal
                                 ? "Applies to all apps unless overridden"
                                 : (profile.bundleIdentifier ?? ""))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if !profile.isGlobal {
                            Button {
                                profileManager.deleteProfile(id: profileID)
                            } label: {
                                Label("Remove Profile", systemImage: "trash")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }
                    .padding(20)

                    Divider()

                    // Mapping list
                    if profile.mappings.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 6) {
                                ForEach(profile.mappings) { mapping in
                                    mappingRow(mapping: mapping)
                                        .padding(.horizontal, 20)
                                }
                            }
                            .padding(.vertical, 16)
                        }
                    }

                    Divider()

                    // Bottom toolbar
                    HStack(spacing: 12) {
                        Button {
                            startDetection(for: profile)
                        } label: {
                            Label("Detect Button…", systemImage: "computermouse")
                        }
                        .buttonStyle(.bordered)
                        .disabled(isDetecting)

                        Spacer()

                        Text("\(profile.mappings.count) mapping\(profile.mappings.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .disabled(isDetecting)

                // Detection overlay
                if isDetecting {
                    detectionOverlay
                }
            }
            .alert("Button Already Mapped",
                   isPresented: Binding(get: { duplicateButtonNumber != nil },
                                        set: { if !$0 { duplicateButtonNumber = nil } })) {
                Button("OK") { duplicateButtonNumber = nil }
            } message: {
                if let n = duplicateButtonNumber {
                    Text("M\(n + 1) is already mapped in this profile. Remove the existing mapping first, or press a different button.")
                }
            }
        } else {
            VStack(spacing: 12) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 36))
                    .foregroundColor(.secondary.opacity(0.4))
                Text("No Profile Selected")
                    .foregroundColor(.secondary)
                Text("Select a profile from the sidebar")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Detection

    private func startDetection(for profile: Profile) {
        isDetecting = true
        // Ensure tap is running during detection (even if no buttons are mapped yet)
        if !HIDManager.shared.hasAccessibilityPermission {
            isDetecting = false
            return
        }
        if HIDManager.shared.eventTap == nil { HIDManager.shared.start() }

        HIDManager.shared.onDetectNextButton = { buttonNumber in
            isDetecting = false
            let alreadyMapped = profile.mappings.contains { $0.buttonNumber == buttonNumber }
            if alreadyMapped {
                duplicateButtonNumber = buttonNumber
            } else {
                let mapping = ButtonMapping(buttonNumber: buttonNumber, action: .none)
                profileManager.addMapping(to: profileID, mapping: mapping)
            }
        }
    }

    private func cancelDetection() {
        HIDManager.shared.onDetectNextButton = nil
        isDetecting = false
    }

    // MARK: - Subviews

    private var detectionOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 64, height: 64)
                    Image(systemName: "computermouse.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.accentColor)
                }

                VStack(spacing: 6) {
                    Text("Press a Mouse Button")
                        .font(.headline)
                    Text("Click M3, M4, M5, or any extra button on your mouse.\nLeft and right click are not supported.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button("Cancel") { cancelDetection() }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(.bordered)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(radius: 20)
            )
            .padding(40)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "computermouse")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.4))
            VStack(spacing: 6) {
                Text("No Button Mappings")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("Click \u{201C}Detect Button\u{201D} below, then press\nM4, M5, or any extra button on your mouse.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func mappingRow(mapping: ButtonMapping) -> some View {
        let bindingIndex = profileManager.profiles.firstIndex { $0.id == profileID }

        if let idx = bindingIndex,
           let mIdx = profileManager.profiles[idx].mappings.firstIndex(where: { $0.id == mapping.id }) {
            return AnyView(
                MappingRowView(
                    mapping: Binding(
                        get: { profileManager.profiles[idx].mappings[mIdx] },
                        set: { profileManager.profiles[idx].mappings[mIdx] = $0 }
                    ),
                    onDelete: {
                        profileManager.removeMapping(from: profileID, mappingID: mapping.id)
                    }
                )
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            )
        }
        return AnyView(EmptyView())
    }
}
