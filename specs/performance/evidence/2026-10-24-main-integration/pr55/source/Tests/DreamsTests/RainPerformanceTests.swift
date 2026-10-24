import Foundation
import Testing
@testable import Dreams

struct RainPerformanceTests {
    @Test @MainActor func optionalTimelinePreservesCommitOverlapAndAbsoluteGPUClocks() throws {
        let recorder = RainPerformanceRecorder(limit: 1, observeTimeline: true)
        let id = try #require(recorder.append(RainFrameMeasurement()))
        let base = recorder.samples[id].submittedAt
        recorder.committed(id, began: base + 1, returned: base + 1.004)
        recorder.completed(id, duration: 0.002, failed: false,
            gpuStartedAt: base + 1.001, gpuEndedAt: base + 1.003)
        let timeline = try #require(recorder.samples[id].timeline)
        #expect(timeline.commitBeganAt == base + 1)
        #expect(timeline.commitReturnedAt == base + 1.004)
        #expect(timeline.gpuStartedAt == base + 1.001)
        #expect(timeline.gpuEndedAt == base + 1.003)
        let data = try JSONEncoder().encode(recorder.samples[id])
        let decoded = try JSONDecoder().decode(RainPerformanceSample.self, from: data)
        #expect(decoded.timeline?.gpuStartedAt == timeline.gpuStartedAt)
        #expect(decoded.timeline?.commitReturnedAt == timeline.commitReturnedAt)
    }

    @Test @MainActor func legacySamplesDecodeWithoutTimelineAndDisabledRecorderOmitsIt() throws {
        let recorder = RainPerformanceRecorder(limit: 1)
        let id = try #require(recorder.append(RainFrameMeasurement()))
        recorder.committed(id, began: 10, returned: 10.1)
        recorder.completed(id, duration: 0.002, failed: false, gpuStartedAt: 10.1, gpuEndedAt: 10.102)
        let data = try JSONEncoder().encode(recorder.samples[id])
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["timeline"] == nil)
        #expect(try JSONDecoder().decode(RainPerformanceSample.self, from: data).timeline == nil)
    }

    @Test @MainActor func invalidOrUnavailableTimelineRemainsMissing() throws {
        let recorder = RainPerformanceRecorder(limit: 1, observeTimeline: true)
        let id = try #require(recorder.append(RainFrameMeasurement()))
        recorder.committed(id, began: .nan, returned: 10)
        recorder.committed(id, began: 10, returned: 9)
        recorder.completed(id, duration: nil, failed: true, gpuStartedAt: 10, gpuEndedAt: 11)
        #expect(recorder.samples[id].timeline?.commitBeganAt == nil)
        #expect(recorder.samples[id].timeline?.gpuStartedAt == nil)
        recorder.completed(id, duration: 0.002, failed: false, gpuStartedAt: 0, gpuEndedAt: .infinity)
        #expect(recorder.samples[id].timeline?.gpuEndedAt == nil)
    }

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

    @Test(arguments: ["normal", "dense", "preview-crop"])
    func feedMeasurementsRejectClippedViewports(name: String) throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("research/performance/scenarios/\(name).json"))
        let scenario = try JSONDecoder().decode(RainPerformanceScenario.self, from: data)
        try scenario.validate()
        if name == "preview-crop" {
            #expect(throws: (any Error).self) { try scenario.validate(feedObservation: true) }
        } else {
            try scenario.validate(feedObservation: true)
        }
    }

    @Test func feedMeasurementsRejectClippingInEitherDimension() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("research/performance/scenarios/normal.json"))
        let source = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        for (key, value) in [("drawableWidth", 800), ("drawableHeight", 600)] {
            var cropped = source
            cropped[key] = value
            let encoded = try JSONSerialization.data(withJSONObject: cropped)
            let scenario = try JSONDecoder().decode(RainPerformanceScenario.self, from: encoded)
            try scenario.validate()
            #expect(throws: (any Error).self) { try scenario.validate(feedObservation: true) }
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

    @Test @MainActor func feedObservationKeepsEventFrameAndRefreshIdentity() throws {
        #expect(!RainPerformanceRecorder(limit: 1).observeFeed)
        let recorder = RainPerformanceRecorder(limit: 2, observeFeed: true)
        let event = UUID()
        let frame = RainFrameMeasurement(observeFeed: recorder.observeFeed)
        frame.feedRefresh = RainFeedRefresh(began: 10, ended: 10.004, succeeded: true,
            onMainThread: true, messageCount: 24, eventIDs: [event])
        frame.eventLetters = [event]
        let first = try #require(recorder.append(frame))
        let second = try #require(recorder.append(RainFrameMeasurement(observeFeed: true)))
        recorder.presented(second, at: 10.08)
        recorder.presented(first, at: 10.04)
        #expect(recorder.samples[first].eventLetters == [event])
        #expect(recorder.samples[first].feedRefresh?.eventIDs == [event])
        #expect(recorder.samples[second].feedRefresh == nil)
        #expect(recorder.samples[second].eventLetters.isEmpty)
    }
}
