import AppKit
import MetalKit
import Testing
@testable import Dreams

/// Opt-in deterministic Metal frames for reviewing the motion without covering a display.
@Suite(.enabled(if: ProcessInfo.processInfo.environment["DREAMS_CAPTURE_TRAILS_DIR"] != nil))
@MainActor
struct RainTrailRenderingTests {
    @Test func captureTrailMotion() async throws {
        let directory = URL(fileURLWithPath: try #require(ProcessInfo.processInfo.environment["DREAMS_CAPTURE_TRAILS_DIR"]))
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let renderer = try RainRenderer(view: MTKView(), restoredGlyphs: true)
        if let raw = ProcessInfo.processInfo.environment["DREAMS_CAPTURE_DECELERATION"], let acceleration = Double(raw) {
            renderer.rainDeceleration = .init(enabled: true, acceleration: acceleration)
        }
        renderer.demoWorkingAgents = 1
        renderer.rainColumnCount = 48
        renderer.rainDensity = 0
        renderer.rainFadeRows = 3
        renderer.rainSpeed = 1
        renderer.brightness = 0.25
        var first = Data()
        var last = Data()
        for frame in 0..<100 {
            let png = try await renderer.previewPNG(posedTime: Float(frame) / 10)
            try png.write(to: directory.appendingPathComponent(String(format: "%03d.png", frame)))
            if frame == 0 { first = png }
            last = png
        }
        #expect(first != last)
    }
}
