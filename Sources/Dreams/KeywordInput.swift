import Foundation

enum KeywordInput {
    /// A hook is observational: empty stdout and exit 0 leave agent control flow unchanged.
    static func runHook(source: String) {
        do {
            let payload = try readJSON()
            guard let session = payload["session_id"] as? String,
                  let event = payload["hook_event_name"] as? String,
                  ["codex", "claude"].contains(source) else { return }
            let agent = payload["agent_id"] as? String
            let id = source + ":" + session + (agent.map { ":" + $0 } ?? "")
            let feed = KeywordFeed()
            if event == "SessionEnd" { try feed.clear(sessionID: id); return }
            let tool = (payload["tool_name"] as? String ?? "").lowercased()
            // Ignore our own publishing calls so they do not replace the explicit keywords.
            if tool.contains("dreams") { return }
            let words: [String]
            switch event {
            case "SessionStart": words = [HookWord.start.text]
            case "UserPromptSubmit": words = [HookWord.task.text]
            case "Stop", "SubagentStop": words = [HookWord.done.text]
            case "PreCompact", "PostCompact": words = [HookWord.context.text]
            case "PreToolUse", "PostToolUse":
                if tool.contains("search") || tool.contains("grep") || tool.contains("glob") { words = [HookWord.search.text] }
                else if tool.contains("edit") || tool.contains("write") || tool.contains("patch") { words = [HookWord.code.text] }
                else if tool.contains("read") || tool.contains("open") || tool.contains("fetch") { words = [HookWord.study.text] }
                else if tool.contains("test") { words = [HookWord.check.text] }
                else if tool.contains("bash") || tool.contains("exec") || tool.contains("shell") { words = [HookWord.terminal.text] }
                else if tool.contains("browser") || tool.contains("cua") { words = [HookWord.interface.text] }
                else if tool.contains("agent") { words = [HookWord.delegate.text] }
                else { words = [HookWord.work.text] }
            default: return
            }
            try feed.publish(sessionID: id, words: words,
                color: source == "codex" ? "cyan" : "amber", ttl: event == "Stop" ? 20 : 90,
                activity: ["SessionStart", "Stop", "SubagentStop"].contains(event) ? .idle : .working,
                actionWeight: event == "PreToolUse" ? 1 : event == "PostToolUse" ? 0.35
                    : event == "UserPromptSubmit" ? 0.5 : 0,
                eventLabel: event == "PreToolUse"
                    ? ToolCallLine.describe(tool: payload["tool_name"] as? String ?? "tool",
                                            input: payload["tool_input"], cwd: payload["cwd"] as? String)
                    : event == "UserPromptSubmit" ? "TASK" : event == "PreCompact" ? "CONTEXT" : nil)
        } catch {
            // A dropped visualization event must never block a tool or continue a stopped agent.
            // Explicit --publish and MCP calls report failures instead of silently dropping them.
        }
    }

    /// Visual fixtures are idle events, never claims of actual agent work.
    static func publishFixtures() throws {
        let feed = KeywordFeed()
        let calls = [
            ToolCallLine.describe(tool: "Bash", input: ["command": "brew install fontforge"]),
            ToolCallLine.describe(tool: "mcp__xcode__BuildProject", input: ["scheme": "Dreams"]),
            // Longer than a column allows: shows the full line and the ellipsis.
            ToolCallLine.describe(tool: "Bash", input: ["command":
                ".venv/bin/python scripts/glyphs/pipeline.py build --out research/glyphs/build && open research/glyphs/build/proof-latin-v1.png"]),
        ]
        for label in calls + ["TASK", "CONTEXT"] {
            try feed.publish(sessionID: "dreams:visual-fixtures", words: ["DEMO"],
                ttl: 15, activity: .idle, eventLabel: label)
        }
    }

    static func runPublish() throws {
        let payload = try readJSON()
        guard let session = payload["session_id"] as? String,
              let words = payload["keywords"] as? [String] else {
            throw DreamsError.unavailable("Expected session_id and keywords.")
        }
        let activity = payload["activity"] as? String ?? "working"
        guard let state = KeywordMessage.Activity(rawValue: activity) else {
            throw DreamsError.unavailable("activity must be working or idle.")
        }
        try KeywordFeed().publish(sessionID: session, words: words,
            color: payload["color"] as? String ?? "cyan",
            ttl: payload["ttl_seconds"] as? Double ?? 90, activity: state)
    }

    private static func readJSON() throws -> [String: Any] {
        var data = Data()
        while let chunk = try FileHandle.standardInput.read(upToCount: 16384), !chunk.isEmpty {
            data.append(chunk)
            if data.count > 1_048_576 { throw DreamsError.unavailable("Hook input exceeds 1 MiB.") }
        }
        guard data.count <= 1_048_576,
              let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw DreamsError.unavailable("Expected a JSON object no larger than 1 MiB.")
        }
        return object
    }
}
