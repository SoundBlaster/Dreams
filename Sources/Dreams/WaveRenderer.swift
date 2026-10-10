import AppKit
import MetalKit

@MainActor
final class WaveRenderer: NSObject {
    private let queue: any MTLCommandQueue
    private let pipeline: any MTLRenderPipelineState
    private var keywords: MatrixRain
    private let library: any MTLLibrary
    private let transparentBackground: Bool
    var matrixStyle = true
    var rainDensity = DreamsPreset.density
    var rainFadeRows = DreamsPreset.fadeRows
    var keywordTint = SIMD3<Float>(0.0, 1.0, 0.39)
    var rainTint = SIMD3<Float>(0.008, 0.26, 0.055)
    var keywordBrightness = DreamsPreset.keywordBrightness
    var rainIdleIntensity = DreamsPreset.idleIntensity
    var rainGlow = DreamsPreset.glow
    var rainSpeed = DreamsPreset.speed
    var rainBrightnessSpread = DreamsPreset.brightnessSpread
    var demoWorkingAgents: Int?
    private let startedAt = ProcessInfo.processInfo.systemUptime
    var brightness: Float = 0.18
    var period: Float = 60
    private(set) var framesRendered = 0

    struct Uniforms {
        var resolution: SIMD2<Float>
        var time: Float
        var brightness: Float
        var period: Float
    }

    init(view: MTKView, restoredGlyphs: Bool = false, transparentBackground: Bool = false) throws {
        self.transparentBackground = transparentBackground
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue(),
              let url = Bundle.module.url(forResource: "Waves", withExtension: "metal") else {
            throw DreamsError.unavailable("Metal is unavailable.")
        }
        let source = try String(contentsOf: url, encoding: .utf8)
        let library = try device.makeLibrary(source: source, options: nil)
        self.library = library
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "waveVertex")
        descriptor.fragmentFunction = library.makeFunction(name: "waveFragment")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        self.queue = queue
        pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        keywords = try MatrixRain(device: device, library: library, restoredGlyphs: restoredGlyphs)
        super.init()
        view.device = device
        view.colorPixelFormat = .bgra8Unorm_srgb
        view.framebufferOnly = true
        view.preferredFramesPerSecond = 30
        view.delegate = self
        view.clearColor = MTLClearColorMake(0, 0, 0, transparentBackground ? 0 : 1)
        view.layer?.isOpaque = !transparentBackground
    }

    func setRestoredGlyphs(_ enabled: Bool) throws {
        // Prepare a complete atlas before replacing the active renderer.
        keywords = try MatrixRain(device: queue.device, library: library, restoredGlyphs: enabled)
    }

    /// Renders our shader into a texture, without capturing any screen content.
    func previewPNG(posedTime: Float? = nil) async throws -> Data {
        let width = 1512
        let height = 982
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm_srgb, width: width, height: height, mipmapped: false)
        textureDescriptor.storageMode = .shared
        textureDescriptor.usage = [.renderTarget]
        guard let texture = queue.device.makeTexture(descriptor: textureDescriptor),
              let buffer = queue.makeCommandBuffer() else {
            throw DreamsError.unavailable("Unable to allocate preview texture.")
        }
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].texture = texture
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0,
            transparentBackground && matrixStyle ? 0 : 1)
        descriptor.colorAttachments[0].storeAction = .store
        guard let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            throw DreamsError.unavailable("Unable to render preview.")
        }
        var uniforms = Uniforms(resolution: SIMD2(Float(width), Float(height)),
            time: Float(ProcessInfo.processInfo.systemUptime - startedAt),
            brightness: matrixStyle ? 0 : brightness, period: period)
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        if !transparentBackground || !matrixStyle {
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        }
        if matrixStyle { keywords.draw(encoder: encoder, resolution: uniforms.resolution,
            brightness: brightness, previewTime: posedTime, demoWorkingAgents: demoWorkingAgents,
            density: rainDensity, fadeRows: rainFadeRows, speed: rainSpeed,
            brightnessSpread: rainBrightnessSpread, glow: rainGlow, idleIntensity: rainIdleIntensity,
            keywordTint: keywordTint, keywordBrightness: keywordBrightness, rainTint: rainTint) }
        encoder.endEncoding()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            buffer.addCompletedHandler { _ in continuation.resume() }
            buffer.commit()
        }
        guard buffer.status == .completed else {
            throw DreamsError.unavailable(buffer.error?.localizedDescription ?? "GPU preview failed.")
        }
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        pixels.withUnsafeMutableBytes { bytes in
            texture.getBytes(bytes.baseAddress!, bytesPerRow: width * 4,
                from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let image = CGImage(width: width, height: height, bitsPerComponent: 8,
                bitsPerPixel: 32, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
                    .union(.byteOrder32Little), provider: provider,
                decode: nil, shouldInterpolate: false, intent: .defaultIntent),
              let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
            throw DreamsError.unavailable("Unable to encode preview PNG.")
        }
        return png
    }
}

extension WaveRenderer: @MainActor MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let buffer = queue.makeCommandBuffer(),
              let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        var uniforms = Uniforms(
            resolution: SIMD2(Float(view.drawableSize.width), Float(view.drawableSize.height)),
            time: Float(ProcessInfo.processInfo.systemUptime - startedAt),
            brightness: matrixStyle ? 0 : brightness, period: period)
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        if !transparentBackground || !matrixStyle {
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        }
        if matrixStyle { keywords.draw(encoder: encoder, resolution: uniforms.resolution,
            brightness: brightness, density: rainDensity, fadeRows: rainFadeRows,
            speed: rainSpeed, brightnessSpread: rainBrightnessSpread, glow: rainGlow, idleIntensity: rainIdleIntensity,
            keywordTint: keywordTint, keywordBrightness: keywordBrightness, rainTint: rainTint) }
        encoder.endEncoding()
        buffer.present(drawable)
        buffer.commit()
        framesRendered += 1
    }
}
