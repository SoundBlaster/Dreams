import Foundation

/// Stable identities describe connected displays; CoreGraphics numeric IDs can change on reconnect.
struct RainDisplay: Equatable {
    let id: String
    let name: String
    let builtIn: Bool
    let isMain: Bool
    let excluded: Bool
}

struct RainDisplaySelection: Equatable {
    enum Mode: String, CaseIterable { case automatic, all, selected }
    var mode: Mode = .automatic
    var selectedIDs: Set<String> = []

    func targets(in displays: [RainDisplay]) -> [RainDisplay] {
        let eligible = displays.filter { !$0.excluded }
        switch mode {
        case .all: return eligible
        case .selected:
            let selected = eligible.filter { selectedIDs.contains($0.id) }
            if !selected.isEmpty { return selected }
        case .automatic: break
        }
        // A closed MacBook lid removes the internal screen from AppKit's inventory.
        let automatic = eligible.first { $0.builtIn } ?? eligible.first { $0.isMain } ?? eligible.first
        return automatic.map { [$0] } ?? []
    }

    static func load(from defaults: UserDefaults = .standard) -> Self {
        Self(mode: Mode(rawValue: defaults.string(forKey: "rainDisplayMode") ?? "") ?? .automatic,
             selectedIDs: Set(defaults.stringArray(forKey: "rainDisplayIDs") ?? []))
    }

    func save(to defaults: UserDefaults = .standard) {
        defaults.set(mode.rawValue, forKey: "rainDisplayMode")
        defaults.set(selectedIDs.sorted(), forKey: "rainDisplayIDs")
    }
}
