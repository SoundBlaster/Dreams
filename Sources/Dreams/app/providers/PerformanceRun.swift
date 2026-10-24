import AppKit
import CryptoKit
import MetalKit

/// A bounded windowed probe using production rendering, not a fullscreen acceptance run.
@MainActor
final class PerformanceRun: NSObject, MTKViewDelegate, NSWindowDelegate {
    private let scenario: RainPerformanceScenario
    private let fixtureHash: String
    private let output: URL
    private let view: MTKView
    private let window: NSWindow
    private let renderer: RainRenderer
    private let recorder: RainPerformanceRecorder
    private let constructionSeconds: Double
    private var started = 0.0
    private var measurementStarted: Double?
    private var finishing = false
    private var occludedFrames = 0
    private var userClosed = false
    private var thermalStates = Set<Int>()

    static func run(arguments: [String]) {
        do {
            guard let index = arguments.firstIndex(of: "--performance-run"), arguments.indices.contains(index + 2),
                  let feed = ProcessInfo.processInfo.environment["DREAMS_FEED_DIRECTORY"],
                  let revision = ProcessInfo.processInfo.environment["DREAMS_PERF_REVISION"], !revision.isEmpty else {
                throw DreamsError.unavailable("Use --performance-run <scenario.json> <report.json> with isolated "
                    + "DREAMS_FEED_DIRECTORY and DREAMS_PERF_REVISION.")
            }
            // An empty dedicated directory prevents private live messages entering a report.
            let files = try FileManager.default.contentsOfDirectory(atPath: feed)
            guard files.isEmpty else { throw DreamsError.unavailable("The performance mailbox must be empty.") }
            guard !FileManager.default.fileExists(atPath: arguments[index + 2]) else {
                throw DreamsError.unavailable("The performance output must not already exist.")
            }
            #if DEBUG
            throw DreamsError.unavailable("Performance runs require Release configuration.")
            #endif
            let application = NSApplication.shared
            application.setActivationPolicy(.regular)
            application.finishLaunching()
            let data = try Data(contentsOf: URL(fileURLWithPath: arguments[index + 1]))
            let scenario = try JSONDecoder().decode(RainPerformanceScenario.self, from: data)
            try scenario.validate()
            let run = try PerformanceRun(scenario: scenario, data: data, output: URL(fileURLWithPath: arguments[index + 2]))
            Task { @MainActor in run.start() }
            withExtendedLifetime(run) { application.run() }
        } catch {
            FileHandle.standardError.write(Data("Dreams performance: \(error.localizedDescription)\n".utf8))
            exit(1)
        }
    }

    private init(scenario: RainPerformanceScenario, data: Data, output: URL) throws {
        self.scenario = scenario
        self.output = output
        fixtureHash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        recorder = RainPerformanceRecorder(limit: Int(scenario.measureSeconds * 120) + 120)
        let size = NSSize(width: 960, height: 960 * Double(scenario.drawableHeight) / Double(scenario.drawableWidth))
        view = MTKView(frame: NSRect(origin: .zero, size: size))
        window = NSWindow(contentRect: view.frame, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.title = "Dreams performance: \(scenario.name)"
        window.contentView = view
        let began = CACurrentMediaTime()
        renderer = try RainRenderer(view: view, restoredGlyphs: scenario.restoredGlyphs, transparentBackground: scenario.transparent)
        constructionSeconds = CACurrentMediaTime() - began
        super.init()
        window.delegate = self
        view.autoResizeDrawable = false
        view.drawableSize = CGSize(width: scenario.drawableWidth, height: scenario.drawableHeight)
        view.delegate = self
        renderer.rainColumnCount = scenario.columns
        renderer.rainDensity = scenario.density
        renderer.rainSearchFraction = scenario.searchFraction
        renderer.rainGlow = scenario.glow
        renderer.rainSpeed = scenario.speed
        renderer.rainFadeRows = scenario.fadeRows
        renderer.rainPulseStrength = scenario.pulseStrength
        renderer.rainBrightnessSpread = scenario.brightnessSpread
        renderer.rainIdleIntensity = 1
        renderer.demoWorkingAgents = 3
    }

    private func start() {
        started = CACurrentMediaTime()
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApplication.shared.activate(ignoringOtherApps: true)
        // Independent of draw callbacks: missing drawable cannot keep a run alive indefinitely.
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(scenario.warmupSeconds + scenario.measureSeconds))
            await finish()
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func windowWillClose(_ notification: Notification) {
        userClosed = true
        Task { @MainActor in await finish() }
    }

    func draw(in view: MTKView) {
        guard !finishing, started > 0 else { return }
        let now = CACurrentMediaTime()
        let elapsed = now - started
        if elapsed >= scenario.warmupSeconds {
            if measurementStarted == nil { measurementStarted = now }
            renderer.performanceRecorder = recorder
            if !window.occlusionState.contains(.visible) { occludedFrames += 1 }
            thermalStates.insert(ProcessInfo.processInfo.thermalState.rawValue)
        }
        renderer.draw(in: view, posedTime: Float(elapsed),
                      referenceSize: CGSize(width: scenario.referenceWidth, height: scenario.referenceHeight))
    }

    private func finish() async {
        guard !finishing else { return }
        finishing = true
        let stopped = CACurrentMediaTime()
        view.isPaused = true
        renderer.performanceRecorder = nil
        let deadline = CACurrentMediaTime() + 3
        while recorder.pendingCallbacks > 0 && CACurrentMediaTime() < deadline {
            try? await Task.sleep(for: .milliseconds(20))
        }
        do {
            let intervals = recorder.presentationIntervals
            let samples = recorder.samples
            let valid = samples.compactMap(\.presentedAt).count >= 2 && recorder.overflow == 0 && recorder.pendingCallbacks == 0
                && !samples.contains(where: { $0.gpuFailed }) && occludedFrames == 0 && !userClosed
                && stopped - (measurementStarted ?? stopped) >= scenario.measureSeconds * 0.9
            let report = PerformanceReport(scenario: scenario, fixtureSHA256: fixtureHash,
                revision: ProcessInfo.processInfo.environment["DREAMS_PERF_REVISION"] ?? "unknown",
                valid: valid, measuredSeconds: stopped - (measurementStarted ?? stopped),
                constructionSeconds: constructionSeconds, device: view.device?.name ?? "unknown",
                os: ProcessInfo.processInfo.operatingSystemVersionString,
                cpu: ProcessInfo.processInfo.processorCount, thermalStates: thermalStates.sorted(),
                backingScale: window.backingScaleFactor, screenMaximumFPS: window.screen?.maximumFramesPerSecond ?? 0,
                screenFrame: NSStringFromRect(window.screen?.frame ?? .zero),
                pendingCallbacks: recorder.pendingCallbacks, overflow: recorder.overflow,
                unavailableDrawable: recorder.unavailableDrawable, occludedFrames: occludedFrames,
                intervalsOver50ms: intervals.filter { $0 > 0.050 }.count,
                intervalsOver100ms: intervals.filter { $0 > 0.100 }.count,
                summaries: recorder.summaries, samples: samples)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(report).write(to: output, options: .atomic)
            print("PERFORMANCE_REPORT=\(output.path) valid=\(valid) frames=\(samples.count)")
            window.orderOut(nil)
            NSApplication.shared.terminate(nil)
        } catch {
            FileHandle.standardError.write(Data("Dreams performance export: \(error)\n".utf8))
            exit(1)
        }
    }
}

private struct PerformanceReport: Encodable {
    let schemaVersion = 1
    let profile = "macOS-windowed-production-renderer"
    let configuration = "Release"
    let clock = "real elapsed time; deterministic default simulation seed 0xD2EA5EED; empty isolated feed; forced steady activity"
    let unavailableMetrics = ["allocator events", "resident/peak memory", "energy", "per-pass GPU counters", "tvOS", "fullscreen compositor"]
    let scenario: RainPerformanceScenario
    let fixtureSHA256: String
    let revision: String
    let valid: Bool
    let measuredSeconds: Double
    let constructionSeconds: Double
    let device: String
    let os: String
    let cpu: Int
    let thermalStates: [Int]
    let backingScale: Double
    let screenMaximumFPS: Int
    let screenFrame: String
    let pendingCallbacks: Int
    let overflow: Int
    let unavailableDrawable: Int
    let occludedFrames: Int
    let intervalsOver50ms: Int
    let intervalsOver100ms: Int
    let summaries: [String: RainMetricSummary]
    let samples: [RainPerformanceSample]
}
