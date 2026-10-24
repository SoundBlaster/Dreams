import Foundation
import QuartzCore

/// Opt-in wall-clock spans. These are not CPU utilization or allocator measurements.
@MainActor
final class RainFrameMeasurement {
    let began = CACurrentMediaTime()
    let observeFeed: Bool
    var feedSeconds = 0.0
    var simulationSeconds = 0.0
    var instancesSeconds = 0.0
    var encodingSeconds = 0.0
    var coreInstances = 0
    var haloInstances = 0
    var bufferCreations = 0
    var bufferBytes = 0
    var glyphRasterizations = 0
    var columns = 0
    var rows = 0
    var feedRefresh: RainFeedRefresh?
    var eventLetters: [UUID] = []

    init(observeFeed: Bool = false) { self.observeFeed = observeFeed }
}

/// Snapshot API timing and event identities, not filesystem syscall counts.
struct RainFeedRefresh: Codable, Sendable {
    let began: Double
    let ended: Double
    let succeeded: Bool
    let onMainThread: Bool
    let messageCount: Int
    let eventIDs: [UUID]
}

/// API call bracket, not an exact driver enqueue timestamp. GPU can start before commit returns.
struct RainFrameTimeline: Codable, Sendable {
    var commitBeganAt: Double?
    var commitReturnedAt: Double?
    var gpuStartedAt: Double?
    var gpuEndedAt: Double?
}

struct RainPerformanceSample: Codable, Sendable {
    let id: Int
    let submittedAt: Double
    let drawSeconds: Double
    let feedSeconds: Double
    let simulationSeconds: Double
    let instancesSeconds: Double
    let encodingSeconds: Double
    let coreInstances: Int
    let haloInstances: Int
    let bufferCreations: Int
    let bufferBytes: Int
    let glyphRasterizations: Int
    let columns: Int
    let rows: Int
    var feedRefresh: RainFeedRefresh?
    var eventLetters: [UUID] = []
    var gpuSeconds: Double?
    var timeline: RainFrameTimeline?
    var presentedAt: Double?
    var gpuCompleted = false
    var gpuFailed = false
    var presentationReported = false
}

struct RainMetricSummary: Codable, Equatable {
    let count: Int
    let p50: Double?
    let p95: Double?
    let p99: Double?
    let maximum: Double?

    init(_ values: [Double]) {
        let sorted = values.filter { $0.isFinite && $0 >= 0 }.sorted()
        count = sorted.count
        func percentile(_ fraction: Double) -> Double? {
            guard !sorted.isEmpty else { return nil }
            return sorted[max(0, Int(ceil(Double(sorted.count) * fraction)) - 1)]
        }
        p50 = percentile(0.5)
        p95 = percentile(0.95)
        p99 = percentile(0.99)
        maximum = sorted.last
    }
}

/// Bounded per-run storage. Callback arrival order does not define presentation order.
@MainActor
final class RainPerformanceRecorder {
    private(set) var samples: [RainPerformanceSample] = []
    private(set) var overflow = 0
    private(set) var unavailableDrawable = 0
    let limit: Int
    let observeFeed: Bool
    let observeTimeline: Bool

    init(limit: Int, observeFeed: Bool = false, observeTimeline: Bool = false) {
        self.limit = limit
        self.observeFeed = observeFeed
        self.observeTimeline = observeTimeline
        samples.reserveCapacity(limit)
    }

    func missedDrawable() { unavailableDrawable += 1 }

    func append(_ frame: RainFrameMeasurement) -> Int? {
        guard samples.count < limit else { overflow += 1; return nil }
        let id = samples.count
        samples.append(RainPerformanceSample(id: id, submittedAt: frame.began,
            drawSeconds: CACurrentMediaTime() - frame.began,
            feedSeconds: frame.feedSeconds, simulationSeconds: frame.simulationSeconds,
            instancesSeconds: frame.instancesSeconds, encodingSeconds: frame.encodingSeconds,
            coreInstances: frame.coreInstances, haloInstances: frame.haloInstances,
            bufferCreations: frame.bufferCreations, bufferBytes: frame.bufferBytes,
            glyphRasterizations: frame.glyphRasterizations, columns: frame.columns, rows: frame.rows,
            feedRefresh: frame.feedRefresh, eventLetters: frame.eventLetters,
            timeline: observeTimeline ? RainFrameTimeline() : nil))
        return id
    }

    func committed(_ id: Int, began: Double, returned: Double) {
        guard samples.indices.contains(id), samples[id].timeline != nil,
              began.isFinite, returned.isFinite, began > 0, returned >= began else { return }
        samples[id].timeline?.commitBeganAt = began
        samples[id].timeline?.commitReturnedAt = returned
    }

    func completed(_ id: Int, duration: Double?, failed: Bool,
                   gpuStartedAt: Double? = nil, gpuEndedAt: Double? = nil) {
        guard samples.indices.contains(id) else { return }
        samples[id].gpuCompleted = true
        samples[id].gpuFailed = failed
        samples[id].gpuSeconds = duration.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
        if !failed, let gpuStartedAt, let gpuEndedAt, gpuStartedAt.isFinite, gpuEndedAt.isFinite,
           gpuStartedAt > 0, gpuEndedAt > gpuStartedAt {
            samples[id].timeline?.gpuStartedAt = gpuStartedAt
            samples[id].timeline?.gpuEndedAt = gpuEndedAt
        }
    }

    func presented(_ id: Int, at time: Double) {
        guard samples.indices.contains(id) else { return }
        samples[id].presentationReported = true
        samples[id].presentedAt = time.isFinite && time > 0 ? time : nil
    }

    var pendingCallbacks: Int {
        samples.filter { !$0.gpuCompleted || !$0.presentationReported }.count
    }

    var presentationIntervals: [Double] {
        let times = samples.compactMap(\.presentedAt).sorted()
        return zip(times.dropFirst(), times).map(-)
    }

    var summaries: [String: RainMetricSummary] {
        ["draw_seconds": RainMetricSummary(samples.map(\.drawSeconds)),
         "feed_seconds": RainMetricSummary(samples.map(\.feedSeconds)),
         "simulation_seconds": RainMetricSummary(samples.map(\.simulationSeconds)),
         "instances_seconds": RainMetricSummary(samples.map(\.instancesSeconds)),
         "encoding_seconds": RainMetricSummary(samples.map(\.encodingSeconds)),
         "gpu_seconds": RainMetricSummary(samples.compactMap(\.gpuSeconds)),
         "presentation_interval_seconds": RainMetricSummary(presentationIntervals)]
    }
}
