import Testing
@testable import Dreams

struct RainCalibrationTests {
    @Test func processCPUDeltaPreservesMissingAndRejectsReversedCounters() {
        let start = RainProcessCPU(userSeconds: 2, systemSeconds: 1)
        #expect(RainProcessCPU(userSeconds: 2.5, systemSeconds: 1.2).delta(from: start)?.userSeconds == 0.5)
        #expect(RainProcessCPU(userSeconds: 1, systemSeconds: 2).delta(from: start) == nil)
        #expect(RainProcessCPU(userSeconds: .nan, systemSeconds: 2).delta(from: start) == nil)
        #expect(RainProcessCPU.read() != nil)
    }

    @Test @MainActor func commonObserverBoundsStorageAndSortsPresentationTime() throws {
        let recorder = RainCalibrationRecorder(limit: 2)
        let first = try #require(recorder.append(at: 10))
        let second = try #require(recorder.append(at: 11))
        #expect(recorder.append(at: 12) == nil && recorder.overflow == 1)
        recorder.finished(first, at: 10.004)
        recorder.finished(second, at: 11.006)
        recorder.presented(second, at: 20.05)
        #expect(recorder.pendingCallbacks == 1)
        recorder.presented(first, at: 20)
        #expect(recorder.pendingCallbacks == 0)
        #expect(abs(try #require(recorder.presentationIntervals.first) - 0.05) < 0.000001)
        let report = recorder.report(mode: .control, cpu: RainProcessCPU(userSeconds: 0.008, systemSeconds: 0.002))
        #expect(report.draw.count == 2 && report.processCPUSecondsPerDraw == 0.005)
    }

    @Test @MainActor func droppedPresentationAndAbsentCPUAreNotZeroCost() throws {
        let recorder = RainCalibrationRecorder(limit: 1)
        let id = try #require(recorder.append(at: 10))
        recorder.finished(id, at: 9)
        recorder.presented(id, at: 0)
        let report = recorder.report(mode: .full, cpu: nil)
        #expect(report.draw.count == 0 && report.draw.p95 == nil)
        #expect(report.cpu == nil && report.processCPUSecondsPerDraw == nil)
        #expect(report.pendingCallbacks == 0 && report.unpresentedSamples == 1)
        #expect(report.presentation.count == 0)
    }
}
