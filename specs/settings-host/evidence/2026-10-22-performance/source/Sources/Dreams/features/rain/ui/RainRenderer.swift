import AppKit
import MetalKit

@MainActor
final class RainRenderer: NSObject {
    private let queue: any MTLCommandQueue
    private var keywords: MatrixRain
    private let library: any MTLLibrary
    private let transparentBackground: Bool
    private var colorPixelFormat: MTLPixelFormat { transparentBackground ? .bgra8Unorm : .bgra8Unorm_srgb }
    var rainColumnCount = DreamsPreset.columnCount
    var rainDensity = DreamsPreset.density
    var rainFadeRows = DreamsPreset.fadeRows
    var keywordTint = SIMD3<Float>(0.0, 1.0, 0.39)
    var rainTint = SIMD3<Float>(0.008, 0.26, 0.055)
    var keywordBrightness = DreamsPreset.keywordBrightness
    var rainIdleIntensity = DreamsPreset.idleIntensity
    var rainGlow = DreamsPreset.glow
    var rainSpeed = DreamsPreset.speed
    var rainSearchFraction = DreamsPreset.searchFraction
    var rainDeceleration = MatrixSimulation.Deceleration()
    var rainBrightnessSpread = DreamsPreset.brightnessSpread
    var rainPulseStrength = DreamsPreset.pulseStrength
    var demoWorkingAgents: Int?
    var brightness: Float = 0.18
    private(set) var framesRendered = 0
    var performanceRecorder: RainPerformanceRecorder?

    init(view: MTKView, restoredGlyphs: Bool = false, transparentBackground: Bool = false) throws {
        self.transparentBackground = transparentBackground
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue(),
              let url = Bundle.module.url(forResource: "Rain", withExtension: "metal") else {
            throw DreamsError.unavailable("Metal is unavailable.")
        }
        let source = try String(contentsOf: url, encoding: .utf8)
        let library = try device.makeLibrary(source: source, options: nil)
        self.library = library
        self.queue = queue
        keywords = try MatrixRain(device: device, library: library, restoredGlyphs: restoredGlyphs,
                                  transparentBackground: transparentBackground)
        super.init()
        view.device = device
        view.colorPixelFormat = colorPixelFormat
        if transparentBackground { view.colorspace = CGColorSpace(name: CGColorSpace.sRGB) }
        view.framebufferOnly = true
        view.preferredFramesPerSecond = 30
        view.delegate = self
        view.clearColor = MTLClearColorMake(0, 0, 0, transparentBackground ? 0 : 1)
        view.layer?.isOpaque = !transparentBackground
    }

    func setRestoredGlyphs(_ enabled: Bool) throws {
        // Prepare a complete atlas before replacing the active renderer.
        keywords = try MatrixRain(device: queue.device, library: library, restoredGlyphs: enabled,
                                  transparentBackground: transparentBackground)
    }

    /// Renders our shader into a texture, without capturing any screen content.
    func previewPNG(posedTime: Float? = nil, pixelSize: SIMD2<Int> = SIMD2(1512, 982),
                    referenceSize: CGSize? = nil) async throws -> Data {
        let width = pixelSize.x
        let height = pixelSize.y
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: colorPixelFormat, width: width, height: height, mipmapped: false)
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
            transparentBackground ? 0 : 1)
        descriptor.colorAttachments[0].storeAction = .store
        guard let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            throw DreamsError.unavailable("Unable to render preview.")
        }
        let size = referenceSize ?? CGSize(width: width, height: height)
        encoder.setViewport(MTLViewport(originX: 0, originY: 0, width: size.width, height: size.height, znear: 0, zfar: 1))
        keywords.draw(encoder: encoder, resolution: SIMD2(Float(size.width), Float(size.height)),
            brightness: brightness, previewTime: posedTime, demoWorkingAgents: demoWorkingAgents,
            columnCount: rainColumnCount, density: rainDensity, fadeRows: rainFadeRows, speed: rainSpeed,
            brightnessSpread: rainBrightnessSpread, glow: rainGlow, idleIntensity: rainIdleIntensity,
            deceleration: rainDeceleration, searchFraction: rainSearchFraction, pulseStrength: rainPulseStrength,
            keywordTint: keywordTint, keywordBrightness: keywordBrightness, rainTint: rainTint)
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
                bitsPerPixel: 32, bytesPerRow: width * 4,
                space: transparentBackground ? CGColorSpace(name: CGColorSpace.sRGB)! : CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
                    .union(.byteOrder32Little), provider: provider,
                decode: nil, shouldInterpolate: false, intent: .defaultIntent),
              let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
            throw DreamsError.unavailable("Unable to encode preview PNG.")
        }
        return png
    }
}

extension RainRenderer: @MainActor MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) { draw(in: view, posedTime: nil) }

    func draw(in view: MTKView, posedTime: Float?, referenceSize: CGSize? = nil) {
        let measurement = performanceRecorder.map { _ in RainFrameMeasurement() }
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let buffer = queue.makeCommandBuffer(),
              let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            performanceRecorder?.missedDrawable()
            return
        }
        // A screen-sized viewport is clipped by the preview drawable, preserving physical glyph size.
        let size = referenceSize ?? view.drawableSize
        encoder.setViewport(MTLViewport(originX: 0, originY: 0, width: size.width, height: size.height, znear: 0, zfar: 1))
        keywords.draw(encoder: encoder,
            resolution: SIMD2(Float(size.width), Float(size.height)),
            brightness: brightness, previewTime: posedTime, demoWorkingAgents: demoWorkingAgents,
            columnCount: rainColumnCount, density: rainDensity, fadeRows: rainFadeRows,
            speed: rainSpeed, brightnessSpread: rainBrightnessSpread, glow: rainGlow, idleIntensity: rainIdleIntensity,
            deceleration: rainDeceleration, searchFraction: rainSearchFraction, pulseStrength: rainPulseStrength,
            keywordTint: keywordTint, keywordBrightness: keywordBrightness, rainTint: rainTint, measurement: measurement)
        encoder.endEncoding()
        buffer.present(drawable)
        if let recorder = performanceRecorder, let measurement, let id = recorder.append(measurement) {
            buffer.addCompletedHandler { command in
                let seconds = command.gpuEndTime - command.gpuStartTime
                let failed = command.status != .completed
                Task { @MainActor in recorder.completed(id, duration: seconds, failed: failed) }
            }
            drawable.addPresentedHandler { presented in
                let time = presented.presentedTime
                Task { @MainActor in recorder.presented(id, at: time) }
            }
        }
        buffer.commit()
        framesRendered += 1
    }
}
