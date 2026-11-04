import AppKit
import MetalKit
import Testing
@testable import Dreams

struct RainFrameBudgetTests {
    @Test func glowKeepsTheThirtyFrameBudget() {
        for screen in [0, 60, 120, 240] {
            #expect(RainFrameBudget.framesPerSecond(glow: 1, screenMaximum: screen) == 30)
            #expect(RainFrameBudget.framesPerSecond(glow: 0.001, screenMaximum: screen) == 30)
            #expect(RainFrameBudget.framesPerSecond(glow: .nan, screenMaximum: screen) == 30)
        }
    }

    @Test func noGlowFollowsTheScreenUpToOneHundredTwenty() {
        #expect(RainFrameBudget.framesPerSecond(glow: 0, screenMaximum: 60) == 60)
        #expect(RainFrameBudget.framesPerSecond(glow: 0, screenMaximum: 120) == 120)
        #expect(RainFrameBudget.framesPerSecond(glow: 0, screenMaximum: 240) == 120)
        // A view outside a window has no screen: keep the previous fixed budget.
        #expect(RainFrameBudget.framesPerSecond(glow: 0, screenMaximum: 0) == 30)
    }

    @Test func haloFloorIsBelowHalfAnSRGBStepAtBlack() {
        #expect(RainFrameBudget.minimumHaloAlpha > 0)
        #expect(RainFrameBudget.minimumHaloAlpha < 1.0 / 255 / 12.92 / 2)
    }
}

@Suite(.serialized, .enabled(if: ProcessInfo.processInfo.environment["DREAMS_TEST_METAL"] == "1"))
@MainActor
struct RainFrameBudgetRenderingTests {
    @Test func rendererAppliesTheGlowBudgetToItsView() throws {
        _ = try #require(ProcessInfo.processInfo.environment["DREAMS_FEED_DIRECTORY"])
        let view = MTKView()
        let renderer = try RainRenderer(view: view)
        renderer.rainGlow = 1
        #expect(view.preferredFramesPerSecond == 30)
        renderer.rainGlow = 0
        // Without a window the screen maximum is unknown.
        #expect(view.preferredFramesPerSecond == 30)
    }

    @Test func invisibleHalosAreNotSubmitted() async throws {
        _ = try #require(ProcessInfo.processInfo.environment["DREAMS_FEED_DIRECTORY"])
        var counts: [Int] = []
        for glow in [1.0, 0.00001] {
            let renderer = try RainRenderer(view: MTKView(), restoredGlyphs: true)
            renderer.rainColumnCount = 48
            renderer.rainDensity = 1
            renderer.rainGlow = glow
            let measurement = RainFrameMeasurement()
            _ = try await renderer.previewPNG(posedTime: 6, measurement: measurement)
            try #require(measurement.coreInstances > 0)
            counts.append(measurement.haloInstances)
        }
        #expect(counts[0] > 0)
        #expect(counts[1] == 0, "Every halo of a 0.001% glow is below the shader's visible floor")
    }
}
