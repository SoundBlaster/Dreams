import Foundation
import QuartzCore
import Darwin

struct KeywordFeedRead: Codable, Sendable {
    let began: Double
    let ended: Double
    let succeeded: Bool
    let onMainThread: Bool
    let messageCount: Int
    let eventIDs: [UUID]
}

struct KeywordFeedSnapshot: Sendable {
    let messages: [KeywordMessage]
    let recentEvents: [KeywordMessage.RainEvent]
    let pressure: Double
    let read: KeywordFeedRead?

    static let empty = Self(messages: [], recentEvents: [], pressure: 0, read: nil)
}

/// One process-local filesystem observer; renderers synchronously read immutable cached values.
@MainActor
final class KeywordFeedReader {
    static let shared = KeywordFeedReader()
    private let feed: KeywordFeed
    private let fallbackSeconds: Double
    private let wallClock: @Sendable () -> Date
    private(set) var snapshot = KeywordFeedSnapshot.empty
    private(set) var revision = 0
    private(set) var consumers = 0
    private var generation = 0
    private var task: Task<Void, Never>?
    private var trigger: AsyncStream<Void>.Continuation?
    private var waiters: [UUID: (after: Double, continuation: CheckedContinuation<Bool, Never>)] = [:]
    var onRead: ((KeywordFeedRead) -> Void)?

    init(feed: KeywordFeed = KeywordFeed(), fallbackSeconds: Double = 1,
         wallClock: @escaping @Sendable () -> Date = { Date() }) {
        self.feed = feed
        self.fallbackSeconds = max(0.05, fallbackSeconds)
        self.wallClock = wallClock
    }

    func acquire() -> KeywordFeedSubscription {
        consumers += 1
        if consumers == 1 {
            generation += 1
            let token = generation
            snapshot = .empty
            revision += 1
            let (stream, continuation) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingNewest(1))
            trigger = continuation
            let feed = feed, interval = fallbackSeconds, wallClock = wallClock
            task = Task(priority: .utility) { [weak self] in
                await Self.observe(feed: feed, interval: interval, stream: stream, signal: continuation,
                                   wallClock: wallClock) { [weak self] value in
                    guard let self, self.generation == token, self.consumers > 0 else { return }
                    self.snapshot = value
                    self.revision += 1
                    if let read = value.read {
                        self.onRead?(read)
                        for (id, waiter) in self.waiters where read.began >= waiter.after {
                            self.waiters.removeValue(forKey: id)
                            waiter.continuation.resume(returning: read.succeeded)
                        }
                    }
                }
            }
        }
        return KeywordFeedSubscription { [weak self] in self?.release() }
    }

    /// Offline image generation can await fresh input; the synchronous frame path never does.
    func refresh() async -> Bool {
        await waitForRead(after: CACurrentMediaTime(), request: true)
    }

    func waitForRead(after: Double, request: Bool = false) async -> Bool {
        guard consumers > 0, waiters.count < 64, !Task.isCancelled else { return false }
        if !request, let read = snapshot.read, read.began >= after { return read.succeeded }
        let id = UUID()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                waiters[id] = (after, continuation)
                if request { trigger?.yield(()) }
                Task { [weak self] in
                    try? await Task.sleep(for: .seconds(2))
                    self?.finishWaiter(id)
                }
            }
        } onCancel: { Task { @MainActor [weak self] in self?.finishWaiter(id) } }
    }

    private func finishWaiter(_ id: UUID) {
        waiters.removeValue(forKey: id)?.continuation.resume(returning: false)
    }

    private func release() {
        consumers -= 1
        guard consumers == 0 else { return }
        generation += 1
        trigger?.finish()
        trigger = nil
        task?.cancel()
        task = nil
        snapshot = .empty
        revision += 1
        for waiter in waiters.values { waiter.continuation.resume(returning: false) }
        waiters.removeAll()
    }

    isolated deinit {
        task?.cancel()
        trigger?.finish()
        for waiter in waiters.values { waiter.continuation.resume(returning: false) }
    }

    /// Dispatch is confined to the filesystem API bridge. No shared mutable state or unchecked Sendable is needed.
    @concurrent
    private static func observe(feed: KeywordFeed, interval: Double, stream: AsyncStream<Void>,
                                signal: AsyncStream<Void>.Continuation,
                                wallClock: @Sendable () -> Date,
                                publish: @escaping @MainActor @Sendable (KeywordFeedSnapshot) -> Void) async {
        let queue = DispatchQueue(label: "Dreams.keyword-feed", qos: .utility)
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + interval, repeating: interval, leeway: .milliseconds(50))
        timer.setEventHandler { signal.yield(()) }
        timer.resume()
        var watch: (source: any DispatchSourceFileSystemObject, device: dev_t, inode: ino_t)?
        var messages: [KeywordMessage] = []
        defer { timer.cancel(); watch?.source.cancel(); signal.finish() }
        signal.yield(())
        for await _ in stream {
            // Bound notification bursts (including our own expired-file pruning).
            do { try await Task.sleep(for: .milliseconds(20)) } catch { break }
            guard !Task.isCancelled else { break }
            // Reconcile inode identity on every fallback too: atomic directory replacement is recoverable.
            try? FileManager.default.createDirectory(at: feed.directory, withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700])
            var info = stat()
            if stat(feed.directory.path, &info) == 0,
               watch == nil || watch?.device != info.st_dev || watch?.inode != info.st_ino {
                watch?.source.cancel()
                watch = nil
                let fd = open(feed.directory.path, O_EVTONLY | O_CLOEXEC)
                if fd >= 0 {
                    let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd,
                        eventMask: [.write, .rename, .delete, .revoke], queue: queue)
                    source.setEventHandler { signal.yield(()) }
                    source.setCancelHandler { close(fd) }
                    source.resume()
                    watch = (source, info.st_dev, info.st_ino)
                }
            }
            let began = CACurrentMediaTime()
            let now = wallClock()
            var succeeded = false
            if let value = try? feed.snapshot(at: now) { messages = value; succeeded = true }
            let ended = CACurrentMediaTime()
            let recent = messages.flatMap { $0.events ?? [] }.filter { now.timeIntervalSince($0.time) < 8 }
                .sorted { $0.time < $1.time }
            let read = KeywordFeedRead(began: began, ended: ended, succeeded: succeeded,
                onMainThread: pthread_main_np() != 0, messageCount: messages.count,
                eventIDs: succeeded ? messages.flatMap { ($0.events ?? []).map(\.id) } : [])
            guard !Task.isCancelled else { break }
            await publish(KeywordFeedSnapshot(messages: messages, recentEvents: recent,
                pressure: KeywordMessage.pressure(messages, at: now), read: read))
        }
    }
}

@MainActor
final class KeywordFeedSubscription {
    private var release: (() -> Void)?
    init(release: @escaping () -> Void) { self.release = release }
    func cancel() { release?(); release = nil }
    isolated deinit { release?() }
}
