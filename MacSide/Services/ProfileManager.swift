import Foundation
import Combine

final class ProfileManager: ObservableObject {
    static let shared = ProfileManager()

    @Published var profiles: [Profile] = [] {
        didSet { save(); updateHIDSuppression() }
    }
    @Published var selectedProfileID: UUID?

    private let storageKey = "com.mouseremapper.profiles"
    private var cancellables = Set<AnyCancellable>()

    private init() {
        load()
        if profiles.isEmpty {
            profiles = [Profile.defaultGlobal]
        }
        selectedProfileID = profiles.first?.id

        // React to active app changes
        ActiveAppMonitor.shared.$frontmostBundleID
            .sink { [weak self] _ in self?.updateHIDSuppression() }
            .store(in: &cancellables)
    }

    // MARK: - Active Profile

    func activeProfile() -> Profile {
        let bundleID = ActiveAppMonitor.shared.frontmostBundleID
        // Try app-specific profile first
        if let bundleID, let appProfile = profiles.first(where: { $0.bundleIdentifier == bundleID }) {
            return appProfile
        }
        // Fall back to global
        return profiles.first(where: { $0.isGlobal }) ?? Profile.defaultGlobal
    }

    // MARK: - Mutations

    func addProfile(_ profile: Profile) {
        profiles.append(profile)
        selectedProfileID = profile.id
    }

    func deleteProfile(id: UUID) {
        guard let idx = profiles.firstIndex(where: { $0.id == id }) else { return }
        let isGlobal = profiles[idx].isGlobal
        guard !isGlobal else { return }  // Can't delete global
        profiles.remove(at: idx)
        selectedProfileID = profiles.first?.id
    }

    func updateProfile(_ profile: Profile) {
        guard let idx = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        profiles[idx] = profile
    }

    func addMapping(to profileID: UUID, mapping: ButtonMapping) {
        guard let idx = profiles.firstIndex(where: { $0.id == profileID }) else { return }
        // Replace if button already mapped
        if let existingIdx = profiles[idx].mappings.firstIndex(where: { $0.buttonNumber == mapping.buttonNumber }) {
            profiles[idx].mappings[existingIdx] = mapping
        } else {
            profiles[idx].mappings.append(mapping)
        }
    }

    func removeMapping(from profileID: UUID, mappingID: UUID) {
        guard let idx = profiles.firstIndex(where: { $0.id == profileID }) else { return }
        profiles[idx].mappings.removeAll { $0.id == mappingID }
    }

    func updateMapping(in profileID: UUID, mapping: ButtonMapping) {
        guard let idx = profiles.firstIndex(where: { $0.id == profileID }) else { return }
        guard let mIdx = profiles[idx].mappings.firstIndex(where: { $0.id == mapping.id }) else { return }
        profiles[idx].mappings[mIdx] = mapping
    }

    // MARK: - HID Suppression

    private func updateHIDSuppression() {
        let profile = activeProfile()
        let buttons = Set(profile.mappings.filter { $0.action != .none }.map { $0.buttonNumber })
        DispatchQueue.main.async {
            HIDManager.shared.suppressedButtons = buttons
        }
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Profile].self, from: data) else { return }
        profiles = decoded
    }
}
