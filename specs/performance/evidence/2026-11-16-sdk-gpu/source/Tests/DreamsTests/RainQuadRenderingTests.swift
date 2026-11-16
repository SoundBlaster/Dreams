import MetalKit
import Testing
@testable import Dreams

/// Keep the desktop strip compatible with the six-vertex FPS/TV entry point.
@Suite(.serialized, .enabled(if: ProcessInfo.processInfo.environment["DREAMS_TEST_METAL"] == "1"))
@MainActor
struct RainQuadRenderingTests {
    @Test(arguments: [false, true], [false, true])
    func stripMatchesTriangles(transparent: Bool, glow: Bool) async throws {
        let device = try #require(MTLCreateSystemDefaultDevice())
        let source = try #require(Bundle.module.url(forResource: "Rain", withExtension: "metal"))
        let library = try await device.makeLibrary(source: String(contentsOf: source, encoding: .utf8), options: nil)
        let queue = try #require(device.makeCommandQueue())
        let atlasDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Unorm,
            width: 16, height: 16, mipmapped: false)
        atlasDescriptor.storageMode = .shared
        atlasDescriptor.usage = .shaderRead
        let atlas = try #require(device.makeTexture(descriptor: atlasDescriptor))
        var texels: [UInt8] = []
        for index in 0..<256 {
            let value = index * 29 + (index / 16) * 17
            texels.append(UInt8(value % 256))
        }
        texels.withUnsafeBytes {
            atlas.replace(region: MTLRegionMake2D(0, 0, 16, 16), mipmapLevel: 0,
                          withBytes: $0.baseAddress!, bytesPerRow: 16)
        }
        var cells: [MatrixRain.Cell] = []
        for index in 0..<24 {
            let x = Float(index % 6) * 0.157 + 0.013
            let y = Float(index / 6) * 0.23 + 0.017
            let rect = SIMD4<Float>(x, y, 0.183, 0.269)
            let uv = SIMD4<Float>(Float(index % 3) * 0.1, Float(index % 5) * 0.05, 0.67, 0.71)
            let color = SIMD4<Float>(0.12, 0.6, 0.23, Float(index % 7 + 1) / 8)
            cells.append(MatrixRain.Cell(rect: rect, uv: uv, color: color))
        }
        let instances = try #require(cells.withUnsafeBytes {
            device.makeBuffer(bytes: $0.baseAddress!, length: $0.count, options: .storageModeShared)
        })
        func render(strip: Bool) async throws -> [UInt8] {
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = library.makeFunction(name: strip ? "matrixStripVertex" : "matrixVertex")
            pipelineDescriptor.fragmentFunction = library.makeFunction(name: "matrixFragment")
            let color = pipelineDescriptor.colorAttachments[0]!
            color.pixelFormat = transparent ? .bgra8Unorm : .bgra8Unorm_srgb
            color.isBlendingEnabled = true
            color.sourceRGBBlendFactor = .sourceAlpha
            color.destinationRGBBlendFactor = glow ? .one : .oneMinusSourceAlpha
            color.sourceAlphaBlendFactor = .one
            color.destinationAlphaBlendFactor = glow ? .one : .oneMinusSourceAlpha
            let pipeline = try await device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            let targetDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: color.pixelFormat,
                width: 317, height: 239, mipmapped: false)
            targetDescriptor.storageMode = .shared
            targetDescriptor.usage = .renderTarget
            let target = try #require(device.makeTexture(descriptor: targetDescriptor))
            let pass = MTLRenderPassDescriptor()
            pass.colorAttachments[0].texture = target
            pass.colorAttachments[0].loadAction = .clear
            pass.colorAttachments[0].storeAction = .store
            pass.colorAttachments[0].clearColor = MTLClearColorMake(0.03, 0.02, 0.01, transparent ? 0.1 : 1)
            let command = try #require(queue.makeCommandBuffer())
            let encoder = try #require(command.makeRenderCommandEncoder(descriptor: pass))
            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(instances, offset: 0, index: 0)
            encoder.setFragmentTexture(atlas, index: 0)
            var parameters = SIMD4<Float>(7.125, 0.7, glow ? 1 : 0, transparent ? 1 : 0)
            encoder.setFragmentBytes(&parameters, length: MemoryLayout<SIMD4<Float>>.stride, index: 0)
            encoder.drawPrimitives(type: strip ? .triangleStrip : .triangle, vertexStart: 0,
                                   vertexCount: strip ? 4 : 6, instanceCount: cells.count)
            encoder.endEncoding()
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                command.addCompletedHandler { _ in continuation.resume() }
                command.commit()
            }
            #expect(command.status == .completed)
            var pixels = [UInt8](repeating: 0, count: 317 * 239 * 4)
            pixels.withUnsafeMutableBytes {
                target.getBytes($0.baseAddress!, bytesPerRow: 317 * 4,
                                from: MTLRegionMake2D(0, 0, 317, 239), mipmapLevel: 0)
            }
            return pixels
        }
        let triangles = try await render(strip: false)
        let strip = try await render(strip: true)
        #expect(strip == triangles)
    }
}
