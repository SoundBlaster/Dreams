import Foundation

/// Order-preserving JSON, so merging Dreams hooks does not reshuffle the user's own settings.
indirect enum OrderedJSON: Equatable {
    case object([(String, OrderedJSON)])
    case array([OrderedJSON])
    case string(String)
    case number(String)
    case bool(Bool)
    case null

    static func == (lhs: OrderedJSON, rhs: OrderedJSON) -> Bool { lhs.serialized() == rhs.serialized() }

    subscript(key: String) -> OrderedJSON? {
        guard case .object(let pairs) = self else { return nil }
        return pairs.first { $0.0 == key }?.1
    }

    func serialized(indent: Int = 0) -> String {
        let pad = String(repeating: " ", count: indent + 2), end = String(repeating: " ", count: indent)
        switch self {
        case .null: return "null"
        case .bool(let value): return value ? "true" : "false"
        case .number(let raw): return raw
        case .string(let value): return Self.quote(value)
        case .array(let items):
            if items.isEmpty { return "[]" }
            return "[\n" + items.map { pad + $0.serialized(indent: indent + 2) }.joined(separator: ",\n") + "\n" + end + "]"
        case .object(let pairs):
            if pairs.isEmpty { return "{}" }
            return "{\n" + pairs.map { pad + Self.quote($0.0) + ": " + $0.1.serialized(indent: indent + 2) }
                .joined(separator: ",\n") + "\n" + end + "}"
        }
    }

    private static func quote(_ text: String) -> String {
        var out = "\""
        for scalar in text.unicodeScalars {
            switch scalar {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            default:
                if scalar.value < 0x20 { out += String(format: "\\u%04x", scalar.value) }
                else { out.unicodeScalars.append(scalar) }
            }
        }
        return out + "\""
    }

    static func parse(_ text: String) throws -> OrderedJSON {
        var parser = Parser(chars: Array(text.unicodeScalars))
        let value = try parser.value()
        parser.skip()
        guard parser.index == parser.chars.count else { throw parser.fail("trailing data") }
        return value
    }

    private struct Parser {
        let chars: [Unicode.Scalar]
        var index = 0

        func fail(_ message: String) -> DreamsError { .unavailable("Invalid JSON: \(message) at \(index).") }
        mutating func skip() { while index < chars.count, " \n\r\t".unicodeScalars.contains(chars[index]) { index += 1 } }

        mutating func expect(_ literal: String) throws {
            for scalar in literal.unicodeScalars {
                guard index < chars.count, chars[index] == scalar else { throw fail("expected \(literal)") }
                index += 1
            }
        }

        mutating func value() throws -> OrderedJSON {
            skip()
            guard index < chars.count else { throw fail("unexpected end") }
            switch chars[index] {
            case "{":
                index += 1
                var pairs: [(String, OrderedJSON)] = []
                skip()
                if index < chars.count, chars[index] == "}" { index += 1; return .object(pairs) }
                while true {
                    skip()
                    let key = try string()
                    skip()
                    try expect(":")
                    pairs.append((key, try value()))
                    skip()
                    guard index < chars.count else { throw fail("unterminated object") }
                    if chars[index] == "," { index += 1; continue }
                    try expect("}")
                    return .object(pairs)
                }
            case "[":
                index += 1
                var items: [OrderedJSON] = []
                skip()
                if index < chars.count, chars[index] == "]" { index += 1; return .array(items) }
                while true {
                    items.append(try value())
                    skip()
                    guard index < chars.count else { throw fail("unterminated array") }
                    if chars[index] == "," { index += 1; continue }
                    try expect("]")
                    return .array(items)
                }
            case "\"": return .string(try string())
            case "t": try expect("true"); return .bool(true)
            case "f": try expect("false"); return .bool(false)
            case "n": try expect("null"); return .null
            default:
                let start = index
                while index < chars.count, "+-0123456789.eE".unicodeScalars.contains(chars[index]) { index += 1 }
                guard index > start else { throw fail("unexpected character") }
                return .number(String(String.UnicodeScalarView(chars[start..<index])))
            }
        }

        mutating func string() throws -> String {
            try expect("\"")
            var out = String.UnicodeScalarView()
            while index < chars.count {
                let c = chars[index]
                index += 1
                if c == "\"" { return String(out) }
                guard c == "\\" else { out.append(c); continue }
                guard index < chars.count else { break }
                let e = chars[index]
                index += 1
                switch e {
                case "n": out.append("\n")
                case "r": out.append("\r")
                case "t": out.append("\t")
                case "b": out.append("\u{8}")
                case "f": out.append("\u{c}")
                case "u":
                    var code = try hex4()
                    if (0xD800..<0xDC00).contains(code), index + 1 < chars.count, chars[index] == "\\", chars[index + 1] == "u" {
                        index += 2
                        let low = try hex4()
                        code = 0x10000 + ((code - 0xD800) << 10) + (low - 0xDC00)
                    }
                    guard let scalar = Unicode.Scalar(code) else { throw fail("bad escape") }
                    out.append(scalar)
                default: out.append(e)
                }
            }
            throw fail("unterminated string")
        }

        mutating func hex4() throws -> UInt32 {
            guard index + 4 <= chars.count,
                  let code = UInt32(String(String.UnicodeScalarView(chars[index..<index + 4])), radix: 16) else {
                throw fail("bad \\u escape")
            }
            index += 4
            return code
        }
    }
}

/// Adds or removes the Dreams hooks in the user-level Codex and Claude Code configs,
/// keeping every other setting and hook and writing a timestamped backup first.
enum HooksInstaller {
    static let events = ["SessionStart", "UserPromptSubmit", "PreToolUse", "PostToolUse", "Stop", "SessionEnd"]
    static let targets = [("codex", ".codex/hooks.json"), ("claude", ".claude/settings.json")]

    static func isOwn(_ command: String) -> Bool {
        command.contains("Dreams.app/Contents/MacOS/Dreams") && command.contains(" --hook ")
    }

    static func shellQuote(_ path: String) -> String { "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'" }

    /// The config with Dreams hooks removed, then (unless uninstalling) added fresh.
    static func merged(_ config: OrderedJSON, source: String, binary: String, uninstall: Bool) -> OrderedJSON {
        var root: [(String, OrderedJSON)]
        if case .object(let pairs) = config { root = pairs } else { root = [] }
        var hooks: [(String, OrderedJSON)] = []
        if case .object(let pairs)? = root.first(where: { $0.0 == "hooks" })?.1 { hooks = pairs }
        hooks = hooks.compactMap { event, groups in
            guard case .array(let items) = groups else { return (event, groups) }
            let kept: [OrderedJSON] = items.compactMap { group in
                guard case .object(var fields) = group, case .array(let handlers)? = group["hooks"] else { return group }
                let remaining = handlers.filter { handler in
                    if case .string(let command)? = handler["command"] { return !isOwn(command) }
                    return true
                }
                if remaining.isEmpty { return nil }
                if let at = fields.firstIndex(where: { $0.0 == "hooks" }) { fields[at].1 = .array(remaining) }
                return .object(fields)
            }
            return kept.isEmpty ? nil : (event, .array(kept))
        }
        if !uninstall {
            for event in events {
                var handler: [(String, OrderedJSON)] = [
                    ("type", .string("command")),
                    ("command", .string(shellQuote(binary) + " --hook " + source)),
                    ("timeout", .number("3")),
                ]
                if event == "PreToolUse" || event == "PostToolUse" { handler.append(("async", .bool(true))) }
                let group = OrderedJSON.object([("hooks", .array([.object(handler)]))])
                if let at = hooks.firstIndex(where: { $0.0 == event }), case .array(let groups) = hooks[at].1 {
                    hooks[at].1 = .array(groups + [group])
                } else {
                    hooks.append((event, .array([group])))
                }
            }
        }
        if let at = root.firstIndex(where: { $0.0 == "hooks" }) {
            if hooks.isEmpty { root.remove(at: at) } else { root[at].1 = .object(hooks) }
        } else if !hooks.isEmpty {
            root.append(("hooks", .object(hooks)))
        }
        return .object(root)
    }

    enum State: String { case notConnected = "not connected", connected, outdated }

    /// Whether the agent's config carries all Dreams hooks for this very binary. `outdated` means Dreams
    /// hooks exist but point elsewhere (the app was moved) or miss an event.
    static func state(source: String, home: URL = homeDirectory(),
                      binary: String? = Bundle.main.executablePath) -> State {
        guard let binary, let relative = targets.first(where: { $0.0 == source })?.1,
              let text = try? String(contentsOf: home.appendingPathComponent(relative), encoding: .utf8),
              let config = try? OrderedJSON.parse(text),
              case .object(let hooks)? = config["hooks"] else { return .notConnected }
        let expected = shellQuote(binary) + " --hook " + source
        var anyOwn = false
        var covered = Set<String>()
        for (event, groups) in hooks {
            guard case .array(let items) = groups else { continue }
            for group in items {
                guard case .array(let handlers)? = group["hooks"] else { continue }
                for handler in handlers {
                    guard case .string(let command)? = handler["command"], isOwn(command) else { continue }
                    anyOwn = true
                    if command == expected { covered.insert(event) }
                }
            }
        }
        if !anyOwn { return .notConnected }
        return covered.isSuperset(of: events) ? .connected : .outdated
    }

    /// `Dreams --install-hooks|--uninstall-hooks [--dry-run]`; returns the report lines.
    static func run(uninstall: Bool, dryRun: Bool, only: [String]? = nil,
                    home: URL = homeDirectory(), binary: String? = Bundle.main.executablePath) throws -> [String] {
        guard let binary else { throw DreamsError.unavailable("Cannot locate the Dreams executable.") }
        var report: [String] = []
        for (source, relative) in targets where only?.contains(source) ?? true {
            let target = home.appendingPathComponent(relative)
            let exists = FileManager.default.fileExists(atPath: target.path)
            let existing = exists ? try OrderedJSON.parse(String(contentsOf: target, encoding: .utf8)) : .object([])
            if exists, case .object = existing {} else if exists {
                throw DreamsError.unavailable("\(target.path) is not a JSON object; left untouched.")
            }
            let updated = merged(existing, source: source, binary: binary, uninstall: uninstall)
            if updated == existing { report.append("\(target.path): unchanged"); continue }
            if dryRun { report.append("\(target.path): would update"); continue }
            try FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
            if exists {
                let stamp = DateFormatter.backupStamp.string(from: Date())
                let backup = target.deletingLastPathComponent().appendingPathComponent(target.lastPathComponent + ".dreams-backup-" + stamp)
                try FileManager.default.copyItem(at: target, to: backup)
                try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: backup.path)
                report.append("Backup: " + backup.path)
            }
            // Atomic replace; a symlinked config keeps pointing at its real file.
            let real = target.resolvingSymlinksInPath()
            try (updated.serialized() + "\n").write(to: real, atomically: true, encoding: .utf8)
            report.append("Updated: " + target.path)
        }
        return report
    }

    static func homeDirectory() -> URL {
        if let home = ProcessInfo.processInfo.environment["HOME"], !home.isEmpty { return URL(fileURLWithPath: home) }
        return FileManager.default.homeDirectoryForCurrentUser
    }
}

private extension DateFormatter {
    static let backupStamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        return formatter
    }()
}
