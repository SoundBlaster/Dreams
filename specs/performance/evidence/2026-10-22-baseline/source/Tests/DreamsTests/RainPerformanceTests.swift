import Foundation
import Testing
@testable import Dreams

struct RainPerformanceTests {
    @Test func percentilesUseNearestRankAndPreserveMissingData() {
        let empty = RainMetricSummary([])
        #expect(empty.count == 0 && empty.p99 == nil && empty.maximum == nil)
        let summary = RainMetricSummary([0.004, 0.001, .nan, -1, 0.003, 0.002])
        #expect(summary.count == 4)
        #expect(summary.p50 == 0.002 && summary.p95 == 0.004 && summary.p99 == 0.004)
    }

    @Test func allScenarioFixturesAreBoundedAndFullySpecified() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        for name in ["normal", "dense", "dense-no-glow", "search-saturated", "preview-crop"] {
            let url = root.appendingPathComponent("research/performance/scenarios/\(name).json")
            let scenario = try JSONDecoder().decode(RainPerformanceScenario.self, from: Data(contentsOf: url))
            try scenario.validate()
            #expect(scenario.name == name)
        }
    }

    @Test func rejectsInvalidBoundsAndMissingRequiredInputs() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("research/performance/scenarios/normal.json"))
        let source = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        for (key, value) in [("measureSeconds", 0), ("drawableWidth", 100_000), ("columns", 241), ("density", -1)] {
            var invalid = source
            invalid[key] = value
            let encoded = try JSONSerialization.data(withJSONObject: invalid)
            #expect(throws: (any Error).self) {
                try JSONDecoder().decode(RainPerformanceScenario.self, from: encoded).validate()
            }
        }
        var missing = source
        missing.removeValue(forKey: "glow")
        let encoded = try JSONSerialization.data(withJSONObject: missing)
        #expect(throws: (any Error).self) {
            _ = try JSONDecoder().decode(RainPerformanceScenario.self, from: encoded)
        }
    }

    @Test @MainActor func asynchronousCallbacksKeepFrameIdentityAndBoundMemory() throws {
        let recorder = RainPerformanceRecorder(limit: 2)
        let first = try #require(recorder.append(RainFrameMeasurement()))
        let second = try #require(recorder.append(RainFrameMeasurement()))
        #expect(recorder.append(RainFrameMeasurement()) == nil && recorder.overflow == 1)
        recorder.presented(second, at: 20.040)
        recorder.completed(first, duration: nil, failed: false)
        recorder.presented(first, at: 20)
        recorder.completed(second, duration: 0.003, failed: false)
        #expect(recorder.pendingCallbacks == 0)
        #expect(recorder.samples[0].gpuSeconds == nil)
        #expect(recorder.samples[1].gpuSeconds == 0.003)
        let interval = try #require(recorder.presentationIntervals.first)
        #expect(abs(interval - 0.040) < 0.000001)
        #expect(recorder.summaries["gpu_seconds"]?.count == 1)
    }

    @Test @MainActor func droppedPresentationIsNotAZeroDurationFrame() throws {
        let recorder = RainPerformanceRecorder(limit: 1)
        let id = try #require(recorder.append(RainFrameMeasurement()))
        recorder.presented(id, at: 0)
        recorder.completed(id, duration: 0, failed: true)
        #expect(recorder.presentationIntervals.isEmpty)
        #expect(recorder.samples[0].presentedAt == nil && recorder.samples[0].gpuFailed)
        #expect(recorder.summaries["gpu_seconds"]?.count == 0)
    }
}
