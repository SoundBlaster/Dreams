#if DREAMS_METAL_PILOT
import AppKit
import MetalKit
import ScreenerScreenCaptureKit
import ScreenerKit

/// Branch-only diagnostic. Never enabled in the normal application/package build.
@MainActor
enum MetalCapturePilot {
    static func launchIfRequested() -> Bool {
        guard let index = CommandLine.arguments.firstIndex(of: "--capture-metal-pilot"),
              CommandLine.arguments.indices.contains(index + 1) else { return false }
        let directory = URL(fileURLWithPath: CommandLine.arguments[index + 1], isDirectory: true)
        let application = NSApplication.shared
        application.setActivationPolicy(.regular)
        Task { @MainActor in
            do { try await run(directory: directory) }
            catch {
                try? String(describing: error).write(to: directory.appendingPathComponent("failure.txt"),
                    atomically: true, encoding: .utf8)
                FileHandle.standardError.write(Data("METAL_PILOT_FAILED=\(error)\n".utf8))
            }
            application.stop(nil)
            application.postEvent(NSEvent.otherEvent(with: .applicationDefined, location: .zero,
                modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil, subtype: 0,
                data1: 0, data2: 0)!, atStart: false)
        }
        application.run()
        return true
    }

    static func run(directory: URL) async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 440),
            styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.title = "Dreams Metal Capture Pilot"
        window.backgroundColor = NSColor(srgbRed: 0.14, green: 0.20, blue: 0.29, alpha: 1)
        let root = PilotRoot(frame: NSRect(x: 0, y: 0, width: 640, height: 440))
        window.contentView = root
        let label = NSTextField(labelWithString: "APPKIT CONTROL · Metal capture boundary")
        label.textColor = .white
        label.frame = NSRect(x: 20, y: 16, width: 600, height: 30)
        root.addSubview(label)
        let view = MTKView(frame: NSRect(x: 20, y: 60, width: 600, height: 360))
        let transparent = !CommandLine.arguments.contains("--pilot-opaque")
        let renderer = try RainRenderer(view: view, transparentBackground: transparent)
        renderer.pilotTime = 0 // Freeze automatic initial draws as well as explicit checkpoints.
        // Readback is diagnostic instrumentation, not a production capture backend.
        let readGPU = !CommandLine.arguments.contains("--pilot-production-surface")
        view.framebufferOnly = !readGPU
        view.isPaused = true
        renderer.rainColumnCount = 48
        renderer.rainDensity = 1
        renderer.rainIdleIntensity = 1
        renderer.rainGlow = 1
        renderer.brightness = 0.6
        root.addSubview(view)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        defer { view.delegate = nil; window.close() }
        try await Task.sleep(for: .milliseconds(500))
        let scale = window.backingScaleFactor
        let permission = CGPreflightScreenCaptureAccess()
        let screener = Screener()
        let trace = try await screener.startSession(name: "Dreams-Metal-boundary",
            appBundleID: "dreams.metal-pilot", tracesDirectory: directory.appendingPathComponent("traces"))
        var rows: [[String: Any]] = []
        do {
            let live = CommandLine.arguments.contains("--pilot-live")
            let checkpoints = live ? (0..<6).map { (String(format: "live-%02d", $0), Float($0)) }
                : [("01-fixed", Float(6)), ("02-advanced", Float(10))]
            for (name, time) in checkpoints {
                label.stringValue = "APPKIT CONTROL · \(name) · t=\(time)"
                if live {
                    renderer.pilotTime = nil
                    view.isPaused = false
                    try await Task.sleep(for: .milliseconds(250))
                    view.isPaused = true
                    try await Task.sleep(for: .milliseconds(100))
                } else {
                    renderer.pilotTime = time
                    view.draw()
                    try await Task.sleep(for: .milliseconds(250))
                }
                root.layoutSubtreeIfNeeded()
                root.displayIfNeeded()
                var gpuMS: Double?
                var gpu: CGImage?
                if readGPU {
                    guard let texture = renderer.pilotTexture else { throw PilotError.noTexture }
                    let gpuStart = ProcessInfo.processInfo.systemUptime
                    gpu = try await readback(texture)
                    gpuMS = (ProcessInfo.processInfo.systemUptime - gpuStart) * 1000
                    try save(gpu!, to: directory.appendingPathComponent("\(name)-gpu.png"))
                }
                let started = ProcessInfo.processInfo.systemUptime
                let hierarchy = try AppKitCaptureSource(view: root).capture()
                let appkitMS = (ProcessInfo.processInfo.systemUptime - started) * 1000
                try save(hierarchy.cgImage, to: directory.appendingPathComponent("\(name)-appkit.png"))
                try await screener.recordFrame(hierarchy, reason: "\(name).AppKit")
                if let gpu {
                    try await screener.recordFrame(CapturedImage(cgImage: gpu, scale: scale), reason: "\(name).GPU-reference")
                }
                var row: [String: Any] = ["name": name, "posedTime": time, "framesRendered": renderer.framesRendered,
                    "appkitMS": appkitMS,
                    "appkitPixels": [hierarchy.cgImage.width, hierarchy.cgImage.height]]
                if let gpu, let gpuMS {
                    row["gpuReadbackMS"] = gpuMS
                    row["gpuPixels"] = [gpu.width, gpu.height]
                }
                if permission {
                    do {
                        let source = ScreenCaptureKitWindowSource(windowID: CGWindowID(window.windowNumber))
                        let captureStart = ProcessInfo.processInfo.systemUptime
                        let image = try await source.record(to: screener, reason: "\(name).ScreenCaptureKit-module")
                        row["screenCaptureKitRecordMS"] = (ProcessInfo.processInfo.systemUptime - captureStart) * 1000
                        row["screenCaptureKitPixels"] = [image.cgImage.width, image.cgImage.height]
                        row["screenCaptureKitScale"] = image.scale
                        row["screenCaptureKitBackend"] = "ScreenerScreenCaptureKit.window"
                        try save(image.cgImage, to: directory.appendingPathComponent("\(name)-sck.png"))

                    } catch { row["screenCaptureKitError"] = String(describing: error) }
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
                    process.arguments = ["-x", "-o", "-l", String(window.windowNumber),
                        directory.appendingPathComponent("\(name)-system.png").path]
                    try process.run()
                    process.waitUntilExit()
                    row["systemScreenshotExit"] = process.terminationStatus
                } else { row["screenCaptureKitSkipped"] = "Screen recording permission not granted; no request made" }
                row["framesRenderedAfterCaptures"] = renderer.framesRendered
                rows.append(row)
            }
            try await screener.stopSession()
        } catch {
            try? await screener.mark("Pilot.failed", metadata: ["error": String(describing: error)])
            try? await screener.stopSession()
            throw error
        }
        let manifest: [String: Any] = ["scale": scale, "windowID": window.windowNumber,
            "screenRecordingPermission": permission, "trace": trace.path, "rows": rows,
            "transparent": transparent, "framebufferOnly": view.framebufferOnly,
            "instrumentation": "posed/frozen or paused live checkpoints; GPU blit reference only with framebufferOnly=false",
            "scope": "SDR BGRA8 sRGB; one window; paused checkpoints; real animation between live checkpoints",
            "live": CommandLine.arguments.contains("--pilot-live")]
        try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys])
            .write(to: directory.appendingPathComponent("manifest.json"))
        print("METAL_PILOT_COMPLETE=\(directory.path)")
    }

    static func readback(_ texture: any MTLTexture) async throws -> CGImage {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: texture.pixelFormat,
            width: texture.width, height: texture.height, mipmapped: false)
        descriptor.storageMode = .shared
        guard let copy = texture.device.makeTexture(descriptor: descriptor),
              let queue = texture.device.makeCommandQueue(), let buffer = queue.makeCommandBuffer(),
              let blit = buffer.makeBlitCommandEncoder() else { throw PilotError.noTexture }
        blit.copy(from: texture, to: copy)
        blit.endEncoding()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            buffer.addCompletedHandler { _ in continuation.resume() }
            buffer.commit()
        }
        guard buffer.status == .completed else { throw PilotError.noTexture }
        var data = Data(count: texture.width * texture.height * 4)
        data.withUnsafeMutableBytes { bytes in
            copy.getBytes(bytes.baseAddress!, bytesPerRow: texture.width * 4,
                from: MTLRegionMake2D(0, 0, texture.width, texture.height), mipmapLevel: 0)
        }
        // Exercise the public custom-buffer ingestion path independently of SCK.
        return try CapturedImage(pixels: data, width: texture.width, height: texture.height,
            bytesPerRow: texture.width * 4, format: .bgra8,
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, scale: 1).cgImage
    }

    static func save(_ image: CGImage, to url: URL) throws {
        guard let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
        else { throw PilotError.noTexture }
        try png.write(to: url)
    }

    enum PilotError: Error { case noTexture }
}

private final class PilotRoot: NSView {
    override var isFlipped: Bool { true }
}
#endif
