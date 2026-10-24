import Foundation
import CryptoKit
import Darwin

struct KeywordMessage: Codable, Equatable, Sendable {
    enum Activity: String, Codable, Sendable { case working, idle }
    let sessionID: String
    let words: [String]
    let color: String
    let updatedAt: Date
    let expiresAt: Date
    var activity: Activity?
    struct RainEvent: Codable, Equatable, Sendable {
        let id: UUID
        let time: Date
        let label: String
    }
    var events: [RainEvent]?
    var actionScore: Double?

    func actionPressure(at now: Date) -> Double {
        guard isWorking, expiresAt > now else { return 0 }
        let age = max(0, now.timeIntervalSince(updatedAt))
        return min(1, max(0, (actionScore ?? 0) * exp(-age / 20) / 8))
    }

    static func pressure(_ messages: [Self], at now: Date = Date()) -> Double {
        min(1, messages.reduce(0) { $0 + $1.actionPressure(at: now) })
    }

    static func workLevel(_ messages: [Self], at now: Date = Date()) -> Double {
        let count = messages.filter { $0.isWorking && $0.expiresAt > now }.count
        guard count > 0 else { return 0 }
        return min(1, 0.5 + Double(count - 1) * 0.18 + pressure(messages, at: now) * 0.32)
    }

    var isWorking: Bool {
        if let activity { return activity == .working }
        // Legacy hook messages predate the explicit activity field.
        return !HookWord.isIdleMarker(words)
    }

    static let colors = ["cyan", "violet", "amber", "mint", "rose"]

    var rgb: SIMD4<Float> {
        switch color {
        case "violet": SIMD4(0.60, 0.38, 0.95, 1)
        case "amber": SIMD4(0.95, 0.62, 0.25, 1)
        case "mint": SIMD4(0.32, 0.85, 0.62, 1)
        case "rose": SIMD4(0.95, 0.38, 0.58, 1)
        default: SIMD4(0.30, 0.72, 0.95, 1)
        }
    }
}

/// A bounded, per-user mailbox shared by GUI, MCP publishers and short-lived hooks.
/// Atomic files prevent partial reads; the nonblocking file lock coordinates processes.
struct KeywordFeed: Sendable {
    let directory: URL

    init(directory: URL? = nil) {
        if let directory { self.directory = directory }
        else if let override = ProcessInfo.processInfo.environment["DREAMS_FEED_DIRECTORY"] {
            self.directory = URL(fileURLWithPath: override, isDirectory: true)
        } else {
            self.directory = FileManager.default.urls(for: .applicationSupportDirectory,
                in: .userDomainMask)[0].appendingPathComponent("Dreams/Keywords", isDirectory: true)
        }
    }

    func publish(sessionID: String, words: [String], color: String = "cyan", ttl: Double = 90,
                 activity: KeywordMessage.Activity = .working, actionWeight: Double = 0, eventLabel: String? = nil) throws {
        guard !sessionID.isEmpty, sessionID.utf8.count <= 192,
              (1...6).contains(words.count), KeywordMessage.colors.contains(color),
              ttl.isFinite, (15...300).contains(ttl) else {
            throw DreamsError.unavailable("Use a session_id up to 192 bytes, 1...6 keywords, a supported color and ttl_seconds 15...300.")
        }
        var cleaned: [String] = []
        for word in words {
            let text = word.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
            guard !text.isEmpty, text.count <= 32, text.utf8.count <= 128,
                  !text.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else {
                throw DreamsError.unavailable("Each keyword must contain 1...32 characters and no control characters.")
            }
            if !cleaned.contains(text) { cleaned.append(text) }
        }
        try withLock {
            let active = try readAndPrune()
            guard active.count < 24 || active.contains(where: { $0.sessionID == sessionID }) else {
                throw DreamsError.unavailable("The feed already has 24 active sessions. Try again after a session expires.")
            }
            let now = Date()
            let previous = active.first { $0.sessionID == sessionID }
            let score = activity == .working
                ? min(12, (previous?.isWorking == true ? (previous?.actionScore ?? 0)
                    * exp(-max(0, now.timeIntervalSince(previous!.updatedAt)) / 20) : 0) + max(0, min(1, actionWeight))) : 0
            var events = (previous?.events ?? []).filter { now.timeIntervalSince($0.time) < 15 }
            if let eventLabel {
                // Labels are TASK / CONTEXT or a tool call line, printed verbatim in one column.
                let label = ToolCallLine.clean(eventLabel)
                if !label.isEmpty, label.count <= ToolCallLine.limit { events.append(.init(id: UUID(), time: now, label: label)) }
            }
            events = Array(events.suffix(24))
            let value = KeywordMessage(sessionID: sessionID, words: cleaned, color: color,
                updatedAt: now, expiresAt: now.addingTimeInterval(ttl), activity: activity, events: events, actionScore: score)
            let url = fileURL(sessionID)
            try JSONEncoder().encode(value).write(to: url, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
        }
    }

    func clear(sessionID: String) throws {
        guard !sessionID.isEmpty, sessionID.utf8.count <= 192 else {
            throw DreamsError.unavailable("Invalid session_id.")
        }
        try withLock {
            let url = fileURL(sessionID)
            if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
        }
    }

    func snapshot(at now: Date = Date()) throws -> [KeywordMessage] { try withLock { try readAndPrune(at: now) } }

    private func fileURL(_ sessionID: String) -> URL {
        let name = SHA256.hash(data: Data(sessionID.utf8)).map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(name + ".json")
    }

    private func readAndPrune(at now: Date = Date()) throws -> [KeywordMessage] {
        let urls = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])
        var messages: [KeywordMessage] = []
        for url in urls where url.pathExtension == "json" {
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? Int.max
            guard size <= 8192,
                  let data = try? Data(contentsOf: url),
                  let message = try? JSONDecoder().decode(KeywordMessage.self, from: data) else { continue }
            if message.expiresAt <= now {
                try? FileManager.default.removeItem(at: url)
            } else if !message.words.isEmpty, message.words.count <= 6 {
                messages.append(message)
            }
        }
        return Array(messages.sorted { $0.sessionID < $1.sessionID }.prefix(24))
    }

    private func withLock<T>(_ body: () throws -> T) throws -> T {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700])
        let fd = open(directory.appendingPathComponent(".lock").path, O_CREAT | O_RDWR, 0o600)
        guard fd >= 0 else { throw DreamsError.unavailable("Cannot open the keyword mailbox.") }
        defer { close(fd) }
        guard flock(fd, LOCK_EX | LOCK_NB) == 0 else {
            throw DreamsError.unavailable("Keyword mailbox is busy; retry the update.")
        }
        defer { flock(fd, LOCK_UN) }
        return try body()
    }
}
