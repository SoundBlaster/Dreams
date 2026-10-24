import MetalKit
import os

@MainActor
final class MatrixRenderer: NSObject, MTKViewDelegate {
    struct Cell {
        var rect: SIMD4<Float>
        var uv: SIMD4<Float>
        var color: SIMD4<Float>
    }

    var tuning = RainTuning()
    private let device: MTLDevice
    private let queue: MTLCommandQueue
    private let library: MTLLibrary
    private let fps = PresentedFPS()
    private var fpsOverlay: FPSOverlay?
    private var fpsEnabled = false
    private let corePipeline: MTLRenderPipelineState
    private let glowPipeline: MTLRenderPipelineState
    private var atlas: FilmAtlas
    private var restoredGlyphs = true
    private var mask: ClockMask?
    private var maskKey = ""
    private var maskAspect = 0.0
    private var nextClockCheck = 0.0
    private var maskTypeface = ClockTypeface.system
    private var maskSize = 0.0
    private var driftLimits = SIMD2<Float>.zero
    private var simulation: MatrixSimulation?
    private var clock = 0.0
    private var lastFrame: CFTimeInterval?
    private var failed = false
    private let onFailure: () -> Void

    init(view: MTKView, onFailure: @escaping () -> Void) throws {
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue() else {
            throw MatrixRenderError.metalUnavailable
        }
        self.device = device
        self.queue = queue
        self.onFailure = onFailure
        atlas = try FilmAtlas(device: device)
        guard let shaderURL = Bundle.main.url(forResource: "Rain", withExtension: "metal") else {
            throw MatrixRenderError.resource("Rain.metal")
        }
        let source = try String(contentsOf: shaderURL, encoding: .utf8)
        let library = try device.makeLibrary(source: source, options: nil)
        self.library = library
        guard let vertex = library.makeFunction(name: "matrixVertex"),
              let fragment = library.makeFunction(name: "matrixFragment") else { throw MatrixRenderError.shader }
        func pipeline(additive: Bool) throws -> MTLRenderPipelineState {
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertex
            descriptor.fragmentFunction = fragment
            let attachment = descriptor.colorAttachments[0]!
            attachment.pixelFormat = .bgra8Unorm_srgb
            attachment.isBlendingEnabled = true
            attachment.sourceRGBBlendFactor = .sourceAlpha
            attachment.destinationRGBBlendFactor = additive ? .one : .oneMinusSourceAlpha
            attachment.sourceAlphaBlendFactor = .one
            attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
            return try device.makeRenderPipelineState(descriptor: descriptor)
        }
        corePipeline = try pipeline(additive: false)
        glowPipeline = try pipeline(additive: true)
        super.init()
        view.device = device
        view.colorPixelFormat = .bgra8Unorm_srgb
        view.clearColor = MTLClearColorMake(0, 0, 0, 1)
        view.preferredFramesPerSecond = 30
        view.delegate = self
    }

    func resume() { lastFrame = nil; fps.reset() }
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { maskKey = "" }

    func draw(in view: MTKView) {
        guard !failed, view.drawableSize.width > 0, view.drawableSize.height > 0 else { return }
        do {
            try drawFrame(in: view)
        } catch {
            failed = true
            Logger(subsystem: "ru.egormerkushev.DreamsTV", category: "renderer").error("Matrix renderer failed: \(String(describing: error))")
            view.isPaused = true
            onFailure()
        }
    }

    private func drawFrame(in view: MTKView) throws {
        let value = tuning.normalized()
        if fpsEnabled != value.showsFPS { fps.reset(); fpsEnabled = value.showsFPS }
        let aspect = view.drawableSize.width / view.drawableSize.height
        let grid = value.grid(aspect: aspect)
        let columns = grid.columns, rows = grid.rows
        if restoredGlyphs != value.restoredGlyphs {
            let replacement = try FilmAtlas(device: device, restored: value.restoredGlyphs)
            atlas = replacement
            restoredGlyphs = value.restoredGlyphs
            simulation = nil
        }
        if simulation?.columns.count != columns || simulation?.rows != rows {
            simulation = MatrixSimulation(columnCount: columns, rows: rows, glyphCount: atlas.variantCount,
                                          seed: UInt64.random(in: 1...UInt64.max), density: value.density, fadeRows: value.fade)
            clock = 0
            lastFrame = nil
        }
        let now = CACurrentMediaTime()
        clock += min(0.1, max(0, now - (lastFrame ?? now))) * value.speed
        lastFrame = now
        simulation?.setDensity(value.density)
        simulation?.setFadeRows(value.fade)
        simulation?.setDeceleration(value.deceleration)
        simulation?.setSearchFraction(value.searchFraction)
        simulation?.advance(to: clock, mutationRate: 1.5)
        let appearanceChanged = maskTypeface != value.clockTypeface || maskSize != value.clockSize
        if value.showsClock && (mask == nil || abs(maskAspect - aspect) > 0.001 || appearanceChanged || now >= nextClockCheck) {
            nextClockCheck = now + 1
            let key = ClockMask.minuteKey(at: Date())
            if mask == nil || key != maskKey || abs(maskAspect - aspect) > 0.001 || appearanceChanged {
                let bitmap = try ClockMask(time: key, aspect: aspect, typeface: value.clockTypeface, size: value.clockSize)
                mask = bitmap
                maskKey = key
                maskAspect = aspect
                maskTypeface = value.clockTypeface
                maskSize = value.clockSize
                driftLimits = SIMD2(Float(max(0, min(0.12, (1 - bitmap.occupiedWidth) / 2 - 0.03))),
                                    Float(max(0, min(0.16, (1 - bitmap.occupiedHeight) / 2 - 0.03))))
            }
        }
        guard let simulation, let pass = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable, let command = queue.makeCommandBuffer(),
              let encoder = command.makeRenderCommandEncoder(descriptor: pass) else { return }
        let cells = makeCells(simulation: simulation, tuning: value, wallTime: now)
        encode(cells.halos, texture: atlas.glow, pipeline: glowPipeline, diffuse: true, encoder: encoder)
        encode(cells.cores, texture: atlas.core, pipeline: corePipeline, diffuse: false, encoder: encoder)
        if value.showsFPS {
            if fpsOverlay == nil, let url = Bundle.main.url(forResource: "DreamsMatrix", withExtension: "ttf") {
                fpsOverlay = try FPSOverlay(device: device, library: library, format: .bgra8Unorm_srgb, fontURL: url)
            }
            if let value = fps.value {
                fpsOverlay?.draw(value, encoder: encoder, size: SIMD2(Float(view.drawableSize.width), Float(view.drawableSize.height)))
            }
            let counter = fps, generation = fps.generation
            // tvOS does not expose MTLDrawable presentation callbacks. Report completed GPU frames.
            command.addCompletedHandler { command in
                if command.status == .completed { counter.presented(at: command.gpuEndTime, generation: generation) }
            }
        }
        encoder.endEncoding()
        command.present(drawable)
        command.commit()
    }

    /// Shared by the drawable path and deterministic renderer regression checks.
    func makeCells(simulation: MatrixSimulation, tuning value: RainTuning, wallTime now: Double) -> (cores: [Cell], halos: [Cell]) {
        let columns = simulation.columns.count, rows = simulation.rows
        var cores: [Cell] = []
        var halos: [Cell] = []
        cores.reserveCapacity(columns * rows)
        halos.reserveCapacity(columns * rows)
        let width: Float = 1.30 * (22.0 / 30.0) / (38.0 / 46.0)
        let globalExposure = Float(value.brightness / 0.18)
        let offset = value.floatingClock
            ? driftLimits * SIMD2(Float(sin(now / 47)), Float(sin(now / 61))) : .zero
        let green = value.color.linear
        for column in simulation.columns.indices {
            for row in 0..<rows {
                let symbol = simulation.columns[column].cells[row]
                let opacity = value.glyphOpacity(simulation.opacity(column: column, row: row))
                let head = simulation.headIntensity(column: column, row: row)
                guard symbol.glyph >= 0, !symbol.isGap || head > 0, opacity > 0.002 else { continue }
                let displayGlyph = simulation.headGlyph(column: column, row: row)
                let center = SIMD2((Float(column) + 0.5) / Float(columns), (Float(row) + 0.5) / Float(rows))
                let illuminated = value.showsClock && (mask?.illuminates(center: center - offset) ?? false)
                let exposure = globalExposure * (value.showsClock ? (illuminated ? 1.6 : 0.22) : 1)
                let ink = symbol.ink(brightnessSpread: value.brightnessSpread)
                    * GlyphPulse.gain(at: now, column: column, row: row, strength: value.pulseStrength)
                let mutation = Float(max(0, 1 - (simulation.time - symbol.flashedAt) / 0.28)) * 0.85
                let white = max(head, mutation)
                let tint = green * ink * opacity * (1 - white) + SIMD3<Float>(0.86, 0.96, 0.88) * white
                let rect = SIMD4<Float>((Float(column) + (1 - width) / 2) / Float(columns),
                                        (Float(row) - 0.16) / Float(rows), width / Float(columns), 1.32 / Float(rows))
                let uv = FilmGlyphs.uv(for: displayGlyph, inset: 18, side: 28, atlasWidth: 512,
                                      atlasHeight: Float(atlas.height), glyphCount: atlas.glyphCount)
                cores.append(Cell(rect: rect, uv: uv, color: SIMD4(tint * exposure, 1)))
                let glowUV = FilmGlyphs.uv(for: displayGlyph, inset: 0, side: 64, atlasWidth: 512,
                                          atlasHeight: Float(atlas.height), glyphCount: atlas.glyphCount)
                let haloRect = SIMD4<Float>(rect.x - rect.z * 18 / 28, rect.y - rect.w * 18 / 28,
                                            rect.z * 64 / 28, rect.w * 64 / 28)
                let saturated = SIMD3(min(1, green.x * 2.4), min(1, green.y * 2.4), min(1, green.z * 2.4))
                let haloTint = saturated * (1 - white) + SIMD3<Float>(0.52, 0.95, 0.65) * white
                // The clock selects ink only. Boosting overlapping halos would reveal a green digit-shaped cloud.
                if value.glow > 0 {
                    let haloExposure = globalExposure * (value.showsClock ? 0.22 : 1)
                    halos.append(Cell(rect: haloRect, uv: glowUV,
                                      color: SIMD4(haloTint * haloExposure,
                                                   (0.30 * ink * opacity + 0.75 * white) * Float(value.glow))))
                }
            }
        }
        return (cores, halos)
    }

    private func encode(_ cells: [Cell], texture: MTLTexture, pipeline: MTLRenderPipelineState,
                        diffuse: Bool, encoder: MTLRenderCommandEncoder) {
        guard !cells.isEmpty else { return }
        let buffer = cells.withUnsafeBytes { bytes in
            device.makeBuffer(bytes: bytes.baseAddress!, length: bytes.count, options: .storageModeShared)
        }
        guard let buffer else { return }
        var noise = SIMD4<Float>(Float(clock), 0.7, diffuse ? 1 : 0, 0)
        encoder.setRenderPipelineState(pipeline)
        encoder.setVertexBuffer(buffer, offset: 0, index: 0)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.setFragmentBytes(&noise, length: MemoryLayout<SIMD4<Float>>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: cells.count)
    }
}
