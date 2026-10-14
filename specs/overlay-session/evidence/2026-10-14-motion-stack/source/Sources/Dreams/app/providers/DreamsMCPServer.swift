import AppKit
import MCP

extension DreamsMain {
    static func runServer(controller: DreamsController, publisherOnly: Bool) async throws {
        let server = Server(name: "dreams", version: "0.2.0", instructions: """
            You control the user's Dreams screen animation. Call dreams_prepare_ui BEFORE taking
            screenshots or sending input to the covered desktop, then dreams_resume after UI work.
            The rain may stay visible while using a separately captured virtual-display window only
            after verifying that your UI tool captures and clicks that window correctly.
            Creating a virtual display does not automatically redirect your computer-use tools.
            Publish short public task labels with dreams_publish_keywords at meaningful milestones.
            Use a unique session_id. These labels are visible on the user's screen; send only words
            intended for display. Publishing never opens the overlay. Hooks can provide automatic
            activity labels while MCP can provide more specific topics.
            """, capabilities: .init(tools: .init()))
        // swiftlint:disable line_length
        let emptySchema: Value = .object(["type": "object", "properties": .object([:]),
                                          "additionalProperties": false])
        var tools: [Tool] = [
            Tool(name: "dreams_publish_keywords", description: "Replace this session's public task keywords. They appear vertically, one letter per row, inside active Matrix rain. Accepts 1...6 short words/phrases, expires after ttl_seconds (15...300, default 90). Does not open or focus any window.", inputSchema: .object([
                "type": "object", "required": ["session_id", "keywords"],
                "properties": .object([
                    "session_id": .object(["type": "string", "minLength": 1, "maxLength": 192]),
                    "keywords": .object(["type": "array", "minItems": 1, "maxItems": 6,
                        "items": .object(["type": "string", "minLength": 1, "maxLength": 32])]),
                    "color": .object(["type": "string", "enum": .array(KeywordMessage.colors.map { .string($0) })]),
                    "ttl_seconds": .object(["type": "number", "minimum": 15, "maximum": 300]),
                    "activity": .object(["type": "string", "enum": ["working", "idle"]])
                ]), "additionalProperties": false
            ])),
            Tool(name: "dreams_clear_keywords", description: "Remove only the public keywords for the given session_id.", inputSchema: .object([
                "type": "object", "required": ["session_id"], "properties": .object([
                    "session_id": .object(["type": "string", "minLength": 1, "maxLength": 192])
                ]), "additionalProperties": false
            ])),
            Tool(name: "dreams_status", description: "Read rain, settings and virtual workspace state, display IDs, bounds and test click count.", inputSchema: emptySchema),
            Tool(name: "dreams_preview", description: "Render the rain and keyword feed to a PNG without capturing the screen. Does not show or hide the overlay.", inputSchema: emptySchema),
            Tool(name: "dreams_start", description: "Show Matrix rain on the displays selected in Settings (automatic by default: built-in, otherwise main). Covers screenshots of those displays. Use prepare_ui before ordinary desktop computer use. Auto-stops after duration_seconds (default 300, maximum 3600).", inputSchema: .object([
                "type": "object", "properties": .object([
                    "duration_seconds": .object(["type": "number", "minimum": 1, "maximum": 3600]),
                    "brightness": .object(["type": "number", "minimum": 0.02, "maximum": 0.35])
                ]), "additionalProperties": false
            ])),
            Tool(name: "dreams_stop", description: "Remove the rain immediately and release the display sleep assertion. Does not destroy the virtual workspace.", inputSchema: emptySchema),
            Tool(name: "dreams_prepare_ui", description: "Remove the rain BEFORE screenshots, clicks or keyboard actions on the covered desktop. The screen is unprotected during UI work. Resume afterward.", inputSchema: emptySchema),
            Tool(name: "dreams_resume", description: "Resume the rain using the last brightness and duration after UI work.", inputSchema: emptySchema),
            Tool(name: "dreams_workspace_create", description: "EXPERIMENTAL: create a separate virtual display using a private macOS API and show a harmless Increment test window. Does not move existing apps or guarantee native agent compatibility.", inputSchema: emptySchema),
            Tool(name: "dreams_workspace_close", description: "Close the test window and disconnect only the virtual display owned by this Dreams process. Other windows placed on it may move to a physical display.", inputSchema: emptySchema)
        ]
        // swiftlint:enable line_length
        if publisherOnly {
            tools = tools.filter { ["dreams_status", "dreams_preview", "dreams_publish_keywords", "dreams_clear_keywords"].contains($0.name) }
        }
        let availableTools = tools
        await server.withMethodHandler(ListTools.self) { _ in .init(tools: availableTools) }
        await server.withMethodHandler(CallTool.self) { parameters in
            do {
                guard availableTools.contains(where: { $0.name == parameters.name }) else {
                    throw MCPError.invalidParams("Tool unavailable in this connection mode.")
                }
                switch parameters.name {
                case "dreams_publish_keywords":
                    guard case .array(let values) = parameters.arguments?["keywords"] else {
                        throw MCPError.invalidParams("keywords must be an array of strings.")
                    }
                    let words = try values.map { value -> String in
                        guard case .string(let word) = value else { throw MCPError.invalidParams("Each keyword must be a string.") }
                        return word
                    }
                    let activity = try parameters.arguments?["activity"].map { try string($0) } ?? "working"
                    guard let state = KeywordMessage.Activity(rawValue: activity) else {
                        throw MCPError.invalidParams("activity must be working or idle.")
                    }
                    try KeywordFeed().publish(sessionID: string(parameters.arguments?["session_id"]), words: words,
                        color: parameters.arguments?["color"].map { try string($0) } ?? "cyan",
                        ttl: number(parameters.arguments?["ttl_seconds"], fallback: 90), activity: state)
                case "dreams_clear_keywords":
                    try KeywordFeed().clear(sessionID: string(parameters.arguments?["session_id"]))
                case "dreams_preview":
                    let png = try await controller.previewPNG()
                    return .init(content: [.image(data: png.base64EncodedString(), mimeType: "image/png", annotations: nil, _meta: nil)], isError: false)
                case "dreams_status": break
                case "dreams_start":
                    try await controller.start(
                        duration: number(parameters.arguments?["duration_seconds"], fallback: 300),
                        brightness: number(parameters.arguments?["brightness"], fallback: 0.18))
                case "dreams_stop", "dreams_prepare_ui": await controller.stop(reason: .agent)
                case "dreams_resume": try await controller.resume()
                case "dreams_workspace_create": try await controller.createWorkspace()
                case "dreams_workspace_close": await controller.closeWorkspace()
                default: throw MCPError.invalidParams("Unknown tool: \(parameters.name)")
                }
                return .init(content: [.text(text: try await controller.statusJSON(), annotations: nil, _meta: nil)], isError: false)
            } catch {
                return .init(content: [.text(text: error.localizedDescription, annotations: nil, _meta: nil)], isError: true)
            }
        }
        try await server.start(transport: CodexCompatibleStdioTransport())
        await server.waitUntilCompleted()
    }

    private static func string(_ value: Value?) throws -> String {
        guard case .string(let text) = value else { throw MCPError.invalidParams("Expected a string argument.") }
        return text
    }

    private static func number(_ value: Value?, fallback: Double) throws -> Double {
        guard let value else { return fallback }
        switch value {
        case .double(let number): return number
        case .int(let number): return Double(number)
        default: throw MCPError.invalidParams("Expected a numeric argument.")
        }
    }
}
