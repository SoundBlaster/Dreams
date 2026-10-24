import Foundation
import QuartzCore
import Darwin
import Testing
import MetalKit
import Synchronization
@testable import Dreams

@MainActor
struct KeywordFeedReaderTests {
    @Test func fallbackPrunesExpiryWithoutAnotherPublisherWrite() async throws {
        let (directory, feed, _) = try fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        let clock = KeywordFeedTestClock()
        let value = KeywordMessage(sessionID: "short", words: ["OLD"], color: "cyan",
            updatedAt: clock.read(), expiresAt: clock.read().addingTimeInterval(0.5))
        let file = directory.appendingPathComponent("short.json")
        try JSONEncoder().encode(value).write(to: file, options: .atomic)
        let reader = KeywordFeedReader(feed: feed, fallbackSeconds: 0.05, wallClock: { clock.read() })
        let lease = reader.acquire()
        defer { lease.cancel() }
        #expect(await reader.refresh())
        try #require(reader.snapshot.messages.count == 1)
        // Advance expiry only after the initial read, without another publisher write or refresh request.
        clock.advance(by: 1)
        while !reader.snapshot.messages.isEmpty {
            let after = try #require(reader.snapshot.read?.ended)
            try #require(await reader.waitForRead(after: after))
        }
        #expect(!FileManager.default.fileExists(atPath: file.path))
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["DREAMS_TEST_METAL"] == "1"))
    func twoRenderersEachDisplayTheSameEventFromOneReader() async throws {
        let (directory, feed, reader) = try fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        try feed.publish(sessionID: "both", words: ["WORK"], eventLabel: "MATRIX")
        let first = try RainRenderer(view: MTKView(), feedReader: reader)
        let second = try RainRenderer(view: MTKView(), feedReader: reader)
        #expect(reader.consumers == 2)
        #expect(await reader.refresh())
        let event = try #require(reader.snapshot.recentEvents.first?.id)
        for renderer in [first, second] {
            renderer.rainColumnCount = 48
            renderer.rainDensity = 1
            renderer.rainSearchFraction = 0
            renderer.rainIdleIntensity = 1
            _ = try await renderer.previewPNG(posedTime: 0)
            let frame = RainFrameMeasurement(observeFeed: true)
            _ = try await renderer.previewPNG(posedTime: 0.4, measurement: frame)
            #expect(frame.eventLetters.contains(event))
        }
    }

    private func fixture() throws -> (URL, KeywordFeed, KeywordFeedReader) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("dreams-reader-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let feed = KeywordFeed(directory: directory)
        // A successful notification test cannot be satisfied by the fallback timer.
        return (directory, feed, KeywordFeedReader(feed: feed, fallbackSeconds: 30))
    }

    @Test func sharedConsumersReceiveNotificationsAndLastReleaseStops() async throws {
        let (directory, feed, reader) = try fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        let first = reader.acquire(), second = reader.acquire()
        #expect(reader.consumers == 2)
        #expect(await reader.refresh())
        let began = CACurrentMediaTime()
        // Reproduce an empty read completing after the boundary but before the publisher commits.
        #expect(await reader.refresh())
        try feed.publish(sessionID: "first", words: ["WORK"], eventLabel: "TASK")
        try await waitForSessions(["first"], reader: reader, after: began)
        #expect(reader.snapshot.messages.map(\.sessionID) == ["first"])
        #expect(reader.snapshot.recentEvents.count == 1)
        #expect(reader.snapshot.read?.onMainThread == false)
        first.cancel()
        #expect(reader.consumers == 1)
        let next = CACurrentMediaTime()
        try feed.publish(sessionID: "second", words: ["WORK"])
        try await waitForSessions(["first", "second"], reader: reader, after: next)
        #expect(reader.snapshot.messages.count == 2)
        second.cancel()
        #expect(reader.consumers == 0 && reader.snapshot.messages.isEmpty)
        #expect(!(await reader.refresh()))
    }

    private func waitForSessions(_ expected: [String], reader: KeywordFeedReader, after: Double) async throws {
        let deadline = CACurrentMediaTime() + 5
        var cursor = after
        while reader.snapshot.messages.map(\.sessionID).sorted() != expected.sorted() {
            try #require(CACurrentMediaTime() < deadline, "Expected notification-driven snapshot within five seconds")
            _ = await reader.waitForRead(after: cursor)
            // An empty or temporarily busy read is not delivery. Await a later observation.
            cursor = (reader.snapshot.read?.ended ?? cursor).nextUp
        }
    }

    @Test func busyMailboxRetainsCacheAndExpiredFilesArePrunedOffMain() async throws {
        let (directory, feed, reader) = try fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        try feed.publish(sessionID: "active", words: ["WORK"])
        let lease = reader.acquire()
        defer { lease.cancel() }
        #expect(await reader.refresh())
        let fd = open(directory.appendingPathComponent(".lock").path, O_RDWR)
        try #require(fd >= 0)
        defer { close(fd) }
        try #require(flock(fd, LOCK_EX | LOCK_NB) == 0)
        #expect(!(await reader.refresh()))
        #expect(reader.snapshot.messages.map(\.sessionID) == ["active"])
        #expect(reader.snapshot.read?.succeeded == false)
        flock(fd, LOCK_UN)
        let expired = directory.appendingPathComponent("expired.json")
        let value = KeywordMessage(sessionID: "expired", words: ["OLD"], color: "cyan",
            updatedAt: Date().addingTimeInterval(-30), expiresAt: Date().addingTimeInterval(-1))
        try JSONEncoder().encode(value).write(to: expired, options: .atomic)
        #expect(await reader.refresh())
        #expect(!FileManager.default.fileExists(atPath: expired.path))
        #expect(reader.snapshot.messages.map(\.sessionID) == ["active"])
        #expect(reader.snapshot.read?.onMainThread == false)
    }

    @Test func replacingDirectoryReattachesWatchAndRestartClearsStaleValues() async throws {
        let (directory, feed, reader) = try fixture()
        let old = directory.appendingPathExtension("old")
        defer {
            try? FileManager.default.removeItem(at: directory)
            try? FileManager.default.removeItem(at: old)
        }
        var lease: KeywordFeedSubscription? = reader.acquire()
        #expect(await reader.refresh())
        try FileManager.default.moveItem(at: directory, to: old)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        #expect(await reader.refresh())
        let began = CACurrentMediaTime()
        try feed.publish(sessionID: "replacement", words: ["NEW"])
        try await waitForSessions(["replacement"], reader: reader, after: began)
        #expect(reader.snapshot.messages.map(\.sessionID) == ["replacement"])
        lease?.cancel()
        lease = nil
        #expect(reader.snapshot.messages.isEmpty && reader.consumers == 0)
        lease = reader.acquire()
        #expect(await reader.refresh())
        #expect(reader.snapshot.messages.map(\.sessionID) == ["replacement"])
        lease = nil
        #expect(reader.consumers == 0)
    }
}

private final class KeywordFeedTestClock: Sendable {
    private let value = Mutex(Date(timeIntervalSince1970: 1_000))

    func read() -> Date { value.withLock { $0 } }
    func advance(by seconds: TimeInterval) { value.withLock { $0.addTimeInterval(seconds) } }
}
