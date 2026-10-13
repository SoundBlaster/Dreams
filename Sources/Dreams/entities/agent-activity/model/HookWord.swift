import Foundation

/// The short words a hook puts into the rain for events that have no tool call line.
enum HookWord: String, CaseIterable {
    case start, task, done, context, search, code, study, check, terminal, interface, delegate, work

    var text: String { Loc.string("hook." + rawValue) }

    /// True for the words of a session that has just started or finished, in any shipped language:
    /// the feed may hold words written under another language setting.
    static func isIdleMarker(_ words: [String]) -> Bool {
        Loc.languages.contains { language in
            guard let bundle = Loc.bundle(for: language) else { return false }
            return [HookWord.done, .start].contains { words == [Loc.string("hook." + $0.rawValue, in: bundle)] }
        }
    }
}
