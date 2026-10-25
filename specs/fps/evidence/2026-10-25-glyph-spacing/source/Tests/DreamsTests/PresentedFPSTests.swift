import Testing
import MetalKit
@testable import Dreams

struct PresentedFPSTests {
    @Test func scaledDigitsStayCenteredInTheirReservedCells() throws {
        let grid = try #require(FPSGrid(columns: 24, rows: 16, row: 4, glyphScale: 1.07))
        let rect = grid.rect(column: 5)
        #expect(abs(rect.x + rect.z / 2 - 5.5 / 24) < 0.000001)
        #expect(abs(rect.y + rect.w / 2 - 4.5 / 16) < 0.000001)
        #expect(abs(rect.z * 24 / (rect.w * 16) - FPSGrid.glyphWidth / FPSGrid.glyphHeight) < 0.000001)
        #expect(FPSGrid(columns: 24, rows: 16, glyphScale: .nan) == nil)
        #expect(FPSGrid(columns: 24, rows: 16, glyphScale: 0) == nil)
    }

    @Test func reservesActualVisibleGridCells() throws {
        let grid = try #require(FPSGrid(columns: 160, rows: 90, visibleColumns: 40, row: 5))
        #expect(grid.contains(column: 36, row: 5))
        #expect(grid.contains(column: 38, row: 5))
        #expect(!grid.contains(column: 39, row: 5))
        #expect(!grid.contains(column: 38, row: 4))
        #expect(grid.rect(column: 38).z == FPSGrid.glyphWidth / 160)
        #expect(FPSGrid(columns: 160, rows: 90, visibleColumns: 4) == nil)
    }

    @Test func measuresIntervalsAndUpdatesOncePerSecond() {
        let counter = PresentedFPS()
        let generation = counter.generation
        for frame in 0..<30 { counter.presented(at: 10 + Double(frame) / 30, generation: generation) }
        #expect(counter.value == nil)
        counter.presented(at: 11, generation: generation)
        #expect(counter.value == 30)
        for frame in 1...15 { counter.presented(at: 11 + Double(frame) / 15, generation: generation) }
        #expect(counter.value == 15)
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["DREAMS_TEST_METAL"] == "1"))
    @MainActor func ownDigitsRenderInTheTopRightCorner() async throws {
        let device = try #require(MTLCreateSystemDefaultDevice())
        let shader = try #require(Bundle.module.url(forResource: "Rain", withExtension: "metal"))
        let font = try #require(Bundle.module.url(forResource: "DreamsMatrix", withExtension: "ttf"))
        let library = try await device.makeLibrary(source: String(contentsOf: shader, encoding: .utf8), options: nil)
        let overlay = try FPSOverlay(device: device, library: library, format: .bgra8Unorm_srgb, fontURL: font)
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb,
            width: 320, height: 180, mipmapped: false)
        descriptor.storageMode = .shared
        descriptor.usage = .renderTarget
        let texture = try #require(device.makeTexture(descriptor: descriptor))
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = texture
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].storeAction = .store
        let queue = try #require(device.makeCommandQueue())
        let command = try #require(queue.makeCommandBuffer())
        let encoder = try #require(command.makeRenderCommandEncoder(descriptor: pass))
        overlay.draw(30, encoder: encoder, grid: try #require(FPSGrid(columns: 16, rows: 9)))
        encoder.endEncoding()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            command.addCompletedHandler { _ in continuation.resume() }
            command.commit()
        }
        #expect(command.status == .completed)
        var pixels = [UInt8](repeating: 0, count: 320 * 180 * 4)
        pixels.withUnsafeMutableBytes {
            texture.getBytes($0.baseAddress!, bytesPerRow: 320 * 4, from: MTLRegionMake2D(0, 0, 320, 180), mipmapLevel: 0)
        }
        let ink = (0..<(320 * 180)).filter { pixels[$0 * 4] > 100 }
        #expect(ink.count > 50)
        #expect(ink.allSatisfy { $0 % 320 > 240 && $0 / 320 >= 16 && $0 / 320 < 44 })
    }

    @Test func resetRejectsPendingCallbacksAndInvalidTimestamps() {
        let counter = PresentedFPS()
        let old = counter.generation
        counter.reset()
        counter.presented(at: 10, generation: old)
        counter.presented(at: 11, generation: old)
        #expect(counter.value == nil)
        let generation = counter.generation
        for time in [Double.nan, .infinity, -1, 0] { counter.presented(at: time, generation: generation) }
        counter.presented(at: 10, generation: generation)
        counter.presented(at: 10, generation: generation)
        counter.presented(at: 9, generation: generation)
        counter.presented(at: 11, generation: generation)
        #expect(counter.value == 1)
    }
}
