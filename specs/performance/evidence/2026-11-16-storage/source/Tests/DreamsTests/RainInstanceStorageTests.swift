import MetalKit
import Testing
@testable import Dreams

@Suite(.serialized, .enabled(if: ProcessInfo.processInfo.environment["DREAMS_TEST_METAL"] == "1"))
@MainActor
struct RainInstanceStorageTests {
    @Test(arguments: ["resize", "glow-off", "inactive"])
    func releasesObsoleteCapacityAndReusesSteadyStorage(transition: String) async throws {
        let device = try #require(MTLCreateSystemDefaultDevice())
        let source = try #require(Bundle.module.url(forResource: "Rain", withExtension: "metal"))
        let library = try await device.makeLibrary(source: String(contentsOf: source, encoding: .utf8), options: nil)
        let queue = try #require(device.makeCommandQueue())
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("dreams-storage-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let reader = KeywordFeedReader(feed: KeywordFeed(directory: directory))
        let subscription = reader.acquire()
        defer { subscription.cancel() }
        try #require(await reader.refresh())
        let rain = try MatrixRain(device: device, library: library, restoredGlyphs: true, feed: reader)
        let environment = ProcessInfo.processInfo.environment
        let output = environment["DREAMS_STORAGE_OUTPUT"].map { URL(fileURLWithPath: $0) }
        if let output { try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true) }
        var observations: [[String: Any]] = []

        func frame(_ name: String, time: Float, columns: Int = 240, small: Bool = false,
                   glow: Double = 1, idle: Double = 1, record: Bool = true) async throws {
            let width = small ? 480 : 270, height = small ? 270 : 480
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb,
                width: width, height: height, mipmapped: false)
            descriptor.storageMode = .shared
            descriptor.usage = .renderTarget
            let target = try #require(device.makeTexture(descriptor: descriptor))
            let pass = MTLRenderPassDescriptor()
            pass.colorAttachments[0].texture = target
            pass.colorAttachments[0].loadAction = .clear
            pass.colorAttachments[0].storeAction = .store
            let command = try #require(queue.makeCommandBuffer())
            let encoder = try #require(command.makeRenderCommandEncoder(descriptor: pass))
            let measurement = RainFrameMeasurement()
            rain.draw(encoder: encoder, resolution: SIMD2(Float(width), Float(height)), brightness: 0.18,
                previewTime: time, columnCount: columns, density: 1, glow: glow, idleIntensity: idle,
                measurement: measurement)
            encoder.endEncoding()
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                command.addCompletedHandler { _ in continuation.resume() }
                command.commit()
            }
            #expect(command.status == .completed)
            guard record else { return }
            let storage = rain.instanceStorage
            observations.append(["step": name, "coreCapacity": storage.coreCapacity,
                "haloCapacity": storage.haloCapacity, "coreCount": measurement.coreInstances,
                "haloCount": measurement.haloInstances,
                "retainedElementBytes": (storage.coreCapacity + storage.haloCapacity) * MemoryLayout<MatrixRain.Cell>.stride])
            if output != nil || environment["DREAMS_STORAGE_BASELINE"] != nil {
                var pixels = [UInt8](repeating: 0, count: width * height * 4)
                pixels.withUnsafeMutableBytes {
                    target.getBytes($0.baseAddress!, bytesPerRow: width * 4,
                                    from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
                }
                let data = Data(pixels), name = "\(transition)-\(name).bgra"
                if let output { try data.write(to: output.appendingPathComponent(name)) }
                if let baseline = environment["DREAMS_STORAGE_BASELINE"] {
                    #expect(data == (try Data(contentsOf: URL(fileURLWithPath: baseline).appendingPathComponent(name))))
                }
            }
        }

        try await frame("warmup", time: 0, record: false)
        try await frame("large", time: 30)
        let large = rain.instanceStorage
        #expect(large.coreCapacity >= 240 * 427)
        #expect(large.haloCapacity >= 240 * 427)
        for index in 1...12 { try await frame("steady", time: 30 + Float(index) / 60, record: false) }
        #expect(rain.instanceStorage.coreIdentity == large.coreIdentity)
        #expect(rain.instanceStorage.haloIdentity == large.haloIdentity)

        if transition == "resize" {
            try await frame("nearby", time: 30.5, columns: 239)
            #expect(rain.instanceStorage.coreIdentity == large.coreIdentity)
            #expect(rain.instanceStorage.haloIdentity == large.haloIdentity)
            try await frame("small", time: 31, columns: 24, small: true)
            #expect(rain.instanceStorage.coreCapacity <= 2 * 24 * 32)
            #expect(rain.instanceStorage.haloCapacity <= 2 * 24 * 32)
            let small = rain.instanceStorage
            for index in 1...12 {
                try await frame("small-steady", time: 31 + Float(index) / 60, columns: 24, small: true, record: false)
            }
            #expect(rain.instanceStorage.coreIdentity == small.coreIdentity)
            #expect(rain.instanceStorage.haloIdentity == small.haloIdentity)
        } else if transition == "glow-off" {
            try await frame("off", time: 31, glow: 0)
            #expect(rain.instanceStorage.haloCapacity == 0)
            #expect(rain.instanceStorage.coreIdentity == large.coreIdentity)
            try await frame("off-again", time: 32, glow: 0)
            #expect(rain.instanceStorage.haloCapacity == 0)
            #expect(rain.instanceStorage.coreIdentity == large.coreIdentity)
            try await frame("on-again", time: 33)
            #expect(rain.instanceStorage.haloCapacity >= 240 * 427)
        } else {
            try await frame("inactive", time: 31, idle: 0)
            #expect(rain.instanceStorage.coreCapacity == 0)
            #expect(rain.instanceStorage.haloCapacity == 0)
            try await frame("inactive-again", time: 32, idle: 0)
            #expect(rain.instanceStorage.coreCapacity == 0)
            #expect(rain.instanceStorage.haloCapacity == 0)
            try await frame("reactivated", time: 33)
            #expect(rain.instanceStorage.coreCapacity > 0)
        }
        if let output {
            let json = try JSONSerialization.data(withJSONObject: observations, options: [.prettyPrinted, .sortedKeys])
            try json.write(to: output.appendingPathComponent("\(transition).json"))
        }
    }
}
