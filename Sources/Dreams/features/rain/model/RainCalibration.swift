import Darwin
import Foundation

enum RainCalibrationMode: String, Codable {
    case control
    case full
}

/// Process CPU consumed inside the collection interval, including asynchronous work.
struct RainProcessCPU: Codable, Equatable {
    let userSeconds: Double
    let systemSeconds: Double

    static func read() -> Self? {
        var usage = rusage()
        guard getrusage(RUSAGE_SELF, &usage) == 0 else { return nil }
        return Self(userSeconds: Double(usage.ru_utime.tv_sec) + Double(usage.ru_utime.tv_usec) / 1_000_000,
                    systemSeconds: Double(usage.ru_stime.tv_sec) + Double(usage.ru_stime.tv_usec) / 1_000_000)
    }

    func delta(from start: Self) -> Self? {
        guard userSeconds.isFinite, systemSeconds.isFinite,
              start.userSeconds >= 0, start.systemSeconds >= 0,
              userSeconds >= start.userSeconds, systemSeconds >= start.systemSeconds else { return nil }
        return Self(userSeconds: userSeconds - start.userSeconds, systemSeconds: systemSeconds - start.systemSeconds)
    }
}

struct RainCalibrationSample: Codable {
    let id: Int
    let beganAt: Double
    var drawSeconds: Double?
    var presentedAt: Double?
    var presentationReported = false
}

/// Identical outer observation for control and full modes; its own cost is not calibrated here.
@MainActor
final class RainCalibrationRecorder {
    private(set) var samples: [RainCalibrationSample] = []
    private(set) var overflow = 0
    private(set) var unavailableDrawable = 0
    let limit: Int

    init(limit: Int) {
        self.limit = limit
        samples.reserveCapacity(limit)
    }

    func missedDrawable() { unavailableDrawable += 1 }

    func append(at time: Double) -> Int? {
        guard samples.count < limit else { overflow += 1; return nil }
        let id = samples.count
        samples.append(RainCalibrationSample(id: id, beganAt: time))
        return id
    }

    func finished(_ id: Int, at time: Double) {
        guard samples.indices.contains(id), time.isFinite, time >= samples[id].beganAt else { return }
        samples[id].drawSeconds = time - samples[id].beganAt
    }

    func presented(_ id: Int, at time: Double) {
        guard samples.indices.contains(id) else { return }
        samples[id].presentationReported = true
        samples[id].presentedAt = time.isFinite && time > 0 ? time : nil
    }

    var pendingCallbacks: Int { samples.filter { !$0.presentationReported }.count }

    var presentationIntervals: [Double] {
        let times = samples.compactMap(\.presentedAt).sorted()
        return zip(times.dropFirst(), times).map(-)
    }

    func report(mode: RainCalibrationMode, cpu: RainProcessCPU?) -> RainCalibrationReport {
        let intervals = presentationIntervals
        return RainCalibrationReport(mode: mode, cpu: cpu,
            processCPUSecondsPerDraw: cpu.flatMap { samples.isEmpty ? nil : ($0.userSeconds + $0.systemSeconds) / Double(samples.count) },
            draw: RainMetricSummary(samples.compactMap(\.drawSeconds)), presentation: RainMetricSummary(intervals),
            intervalsOver50ms: intervals.filter { $0 > 0.050 }.count, intervalsOver100ms: intervals.filter { $0 > 0.100 }.count,
            pendingCallbacks: pendingCallbacks, overflow: overflow, unavailableDrawable: unavailableDrawable,
            unpresentedSamples: samples.filter { $0.presentedAt == nil }.count, samples: samples)
    }
}

struct RainCalibrationReport: Encodable {
    let mode: RainCalibrationMode
    let scope = "Full collector minus nil collector with identical outer observer; common observer cost excluded."
    let cpu: RainProcessCPU?
    let processCPUSecondsPerDraw: Double?
    let draw: RainMetricSummary
    let presentation: RainMetricSummary
    let intervalsOver50ms: Int
    let intervalsOver100ms: Int
    let pendingCallbacks: Int
    let overflow: Int
    let unavailableDrawable: Int
    let unpresentedSamples: Int
    let samples: [RainCalibrationSample]
}
