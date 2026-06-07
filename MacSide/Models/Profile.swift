import Foundation

struct ButtonMapping: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var buttonNumber: Int   // 2=M3/middle, 3=M4, 4=M5, 5=M6…
    var action: ButtonAction

    var buttonLabel: String {
        switch buttonNumber {
        case 2: return "M3"
        case 3: return "M4"
        case 4: return "M5"
        case 5: return "M6"
        case 6: return "M7"
        default: return "M\(buttonNumber)"
        }
    }
}

struct Profile: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var bundleIdentifier: String?   // nil = global
    var appIconName: String?
    var mappings: [ButtonMapping] = []

    var isGlobal: Bool { bundleIdentifier == nil }

    static let defaultGlobal = Profile(name: "Global", bundleIdentifier: nil)
}
