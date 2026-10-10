import Foundation

/// One-line, on-screen form of a tool call for the rain: `bash: brew install fontforge`.
/// The line is shown verbatim (case and spaces kept), so secrets are masked first.
enum ToolCallLine {
    /// Characters a call line may occupy in one rain column (72 rows).
    static let limit = 60

    static func describe(tool: String, input: Any?, cwd: String? = nil) -> String {
        let (name, pathLike) = shortName(tool)
        var body = argument(of: tool, input: input)
        if let cwd, !cwd.isEmpty {
            if pathLike, body.hasPrefix(cwd + "/") { body = String(body.dropFirst(cwd.count + 1)) }
            // Agents often prefix commands with `cd <cwd> &&`; it says nothing on screen.
            for prefix in ["cd " + cwd + " && ", "cd \"" + cwd + "\" && "] where body.hasPrefix(prefix) {
                body = String(body.dropFirst(prefix.count))
            }
        }
        body = redact(clean(body))
        guard !body.isEmpty else { return name }
        let room = limit - name.count - 2
        if body.count > room {
            // Paths keep their end (the file), commands keep their start (the program).
            body = pathLike ? "…" + String(body.suffix(room - 1)) : String(body.prefix(room - 1)) + "…"
        }
        return name + ": " + body
    }

    /// Short lowercase name and whether the argument is a path.
    static func shortName(_ tool: String) -> (String, Bool) {
        if tool.hasPrefix("mcp__") { return ("mcp", false) }
        switch tool.lowercased() {
        case "bash", "shell", "local_shell", "exec_command", "unified_exec", "container.exec": return ("bash", false)
        case "read", "view", "read_file": return ("read", true)
        case "edit", "multiedit", "str_replace_based_edit_tool": return ("edit", true)
        case "write", "write_file": return ("write", true)
        case "notebookedit": return ("notebook", true)
        case "apply_patch": return ("patch", true)
        case "glob": return ("glob", true)
        case "grep": return ("grep", false)
        case "webfetch": return ("fetch", false)
        case "websearch", "web_search": return ("search", false)
        case "task", "agent": return ("agent", false)
        case "todowrite", "update_plan": return ("plan", false)
        default: return (tool.lowercased(), false)
        }
    }

    private static func argument(of tool: String, input: Any?) -> String {
        if tool.hasPrefix("mcp__") {
            // mcp__server__tool: double underscores separate server and tool.
            let pieces = tool.components(separatedBy: "__").dropFirst().filter { !$0.isEmpty }
            let target = pieces.joined(separator: ".")
            let first = (input as? [String: Any]).flatMap(firstString)
            return [target, first].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
        }
        if let text = input as? String { return text }
        guard let fields = input as? [String: Any] else { return "" }
        for key in ["command", "cmd", "pattern", "query", "url", "file_path", "notebook_path", "path",
                    "description", "prompt", "patch", "input"] {
            if let value = fields[key] { return text(value) }
        }
        return firstString(fields) ?? ""
    }

    private static func text(_ value: Any) -> String {
        if let string = value as? String { return string }
        if let list = value as? [String] {
            // Codex shells arrive as ["bash", "-lc", "<script>"]: show the script.
            if list.count == 3, ["bash", "sh", "zsh"].contains(list[0]), ["-lc", "-c"].contains(list[1]) { return list[2] }
            return list.joined(separator: " ")
        }
        return ""
    }

    private static func firstString(_ fields: [String: Any]) -> String? {
        fields.keys.sorted().lazy.compactMap { key -> String? in
            let value = text(fields[key]!)
            return value.isEmpty ? nil : value
        }.first
    }

    /// One line, single spaces, no control characters.
    static func clean(_ text: String) -> String {
        let scalars = text.unicodeScalars.map { CharacterSet.controlCharacters.contains($0) ? " " : String($0) }
        return scalars.joined().split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    /// Masks values that look like credentials. Over-masking is preferred: the rain is
    /// visible to anyone who sees the screen, including screen shares and recordings.
    static func redact(_ text: String) -> String {
        let secretWord = "[A-Za-z0-9_.-]*(?:token|secret|passw(?:or)?d|api[-_]?key|access[-_]?key|private[-_]?key|credential|auth)[A-Za-z0-9_-]*"
        let value = "(\"[^\"]*\"|'[^']*'|[^\\s\"']+)"
        // Order matters: the scheme rule runs first, otherwise `Authorization: Bearer x`
        // would mask only the word "Bearer" and leave the token itself visible.
        let rules: [(String, String)] = [
            ("(?i)\\b(bearer|basic|token)\\s+[A-Za-z0-9._~+/=-]+", "$1 ***"),     // Authorization schemes
            ("(?i)(" + secretWord + ")(\\s*[:=]\\s*)" + value, "$1$2***"),       // KEY=value, key: value
            ("(?i)(--?" + secretWord + ")(\\s+)" + value, "$1$2***"),             // --password value
            ("(://)[^/\\s@]+@", "$1***@"),                                          // user:pass@host
            ("[A-Za-z0-9+/=_-]{40,}", "***"),                                       // long opaque tokens
        ]
        return rules.reduce(text) { result, rule in
            result.replacingOccurrences(of: rule.0, with: rule.1, options: .regularExpression)
        }
    }
}
