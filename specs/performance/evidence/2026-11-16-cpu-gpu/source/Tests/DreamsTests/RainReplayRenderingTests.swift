import AppKit
import MetalKit
import Testing
@testable import Dreams

/// Export on the baseline, then compare the candidate at identical simulation times.
/// Both directories are explicit; ordinary test runs neither record nor accept goldens.
@Suite(.serialized, .enabled(if: ProcessInfo.processInfo.environment["DREAMS_REPLAY_OUTPUT"] != nil))
@MainActor
struct RainReplayRenderingTests {
    @Test(arguments: [false, true], [false, true])
    func replayMatchesBaseline(restored: Bool, transparent: Bool) async throws {
        let environment = ProcessInfo.processInfo.environment
        let output = URL(fileURLWithPath: try #require(environment["DREAMS_REPLAY_OUTPUT"]))
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("dreams-replay-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let feed = KeywordFeed(directory: directory)
        // Construct before publishing so the first event exercises the surge and packet path.
        let reader = KeywordFeedReader(feed: feed)
        let renderer = try RainRenderer(view: MTKView(), restoredGlyphs: restored,
                                        transparentBackground: transparent, feedReader: reader)
        try #require(await reader.refresh())
        let message = KeywordMessage(sessionID: "replay", words: ["MATRIX", "ПРОВЕРКА"], color: "mint",
            updatedAt: Date(), expiresAt: Date().addingTimeInterval(300), activity: .working,
            events: [.init(id: UUID(), time: Date(), label: "swift build --test")], actionScore: 0)
        try JSONEncoder().encode(message).write(to: directory.appendingPathComponent("fixture.json"), options: .atomic)
        try #require(await reader.refresh())
        renderer.rainColumnCount = 48
        renderer.rainDensity = 1
        renderer.rainIdleIntensity = 1
        renderer.rainSearchFraction = 1
        renderer.demoWorkingAgents = 3
        for (index, time) in [Float(0), 0.4, 1, 3, 6, 9, 17, 1].enumerated() {
            // Exercise both passes, grid reconstruction and time rewind on one renderer.
            renderer.rainGlow = index.isMultiple(of: 2) ? 0 : 1
            if index == 5 { renderer.rainColumnCount = 64 }
            let png = try await renderer.previewPNG(posedTime: time, pixelSize: SIMD2(640, 360))
            let name = "replay-\(restored)-\(transparent)-\(index).png"
            try png.write(to: output.appendingPathComponent(name))
            if let baseline = environment["DREAMS_REPLAY_BASELINE"] {
                let expected = try Data(contentsOf: URL(fileURLWithPath: baseline).appendingPathComponent(name))
                #expect(png == expected, "Deterministic rendered PNG differs: \(name)")
            }
        }
    }
}
