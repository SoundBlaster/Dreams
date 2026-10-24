import CoreText
import Metal

/// A tiny, fixed-width readout using Dreams' own digits and the rain's Metal pipeline.
@MainActor
final class FPSOverlay {
    private struct Cell {
        var rect: SIMD4<Float>
        var uv: SIMD4<Float>
        var color: SIMD4<Float>
    }
    private let pipeline: any MTLRenderPipelineState
    private let texture: any MTLTexture

    init(device: any MTLDevice, library: any MTLLibrary, format: MTLPixelFormat, fontURL: URL) throws {
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        let font = CTFontCreateWithName("DreamsMatrix-Regular" as CFString, 26, nil)
        var codes = Array("0123456789".utf16)
        var glyphs = [CGGlyph](repeating: 0, count: codes.count)
        guard CTFontGetGlyphsForCharacters(font, &codes, &glyphs, codes.count), glyphs.allSatisfy({ $0 != 0 }) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        var pixels = [UInt8](repeating: 0, count: 640 * 64)
        pixels.withUnsafeMutableBytes { bytes in
            let context = CGContext(data: bytes.baseAddress, width: 640, height: 64, bitsPerComponent: 8,
                                    bytesPerRow: 640, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: 0)!
            context.setFillColor(gray: 1, alpha: 1)
            context.setFont(CTFontCopyGraphicsFont(font, nil))
            context.setFontSize(26)
            for index in glyphs.indices {
                var glyph = glyphs[index]
                var bounds = CGRect.zero
                CTFontGetBoundingRectsForGlyphs(font, .default, &glyph, &bounds, 1)
                let position = CGPoint(x: CGFloat(index * 64 + 32) - bounds.midX, y: 32 - bounds.midY)
                context.showGlyphs([glyph], at: [position])
            }
        }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Unorm, width: 640, height: 64, mipmapped: false)
        descriptor.storageMode = .shared
        guard let texture = device.makeTexture(descriptor: descriptor) else { throw CocoaError(.coderInvalidValue) }
        pixels.withUnsafeBytes { texture.replace(region: MTLRegionMake2D(0, 0, 640, 64), mipmapLevel: 0,
                                                withBytes: $0.baseAddress!, bytesPerRow: 640) }
        self.texture = texture
        let pipeline = MTLRenderPipelineDescriptor()
        pipeline.vertexFunction = library.makeFunction(name: "matrixVertex")
        pipeline.fragmentFunction = library.makeFunction(name: "matrixFragment")
        let color = pipeline.colorAttachments[0]!
        color.pixelFormat = format
        color.isBlendingEnabled = true
        color.sourceRGBBlendFactor = .sourceAlpha
        color.destinationRGBBlendFactor = .oneMinusSourceAlpha
        color.sourceAlphaBlendFactor = .one
        color.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        self.pipeline = try device.makeRenderPipelineState(descriptor: pipeline)
    }

    func draw(_ value: Int, encoder: any MTLRenderCommandEncoder, size: SIMD2<Float>, transparent: Bool = false, topInset: Float = 32) {
        let digits = String(min(999, max(0, value))).compactMap(\.wholeNumberValue)
        let side: Float = 40
        let margin: Float = 32
        var cells: [Cell] = []
        for (index, digit) in digits.enumerated() {
            let x = size.x - margin - Float(digits.count - index) * 26
            let uv = SIMD4<Float>((Float(digit * 64) + 12) / 640, 12 / 64, 40 / 640, 40 / 64)
            let rect = SIMD4<Float>(x / size.x, topInset / size.y, side / size.x, side / size.y)
            let shadow = rect + SIMD4<Float>(2 / size.x, 2 / size.y, 0, 0)
            cells.append(Cell(rect: shadow, uv: uv, color: SIMD4(0, 0, 0, 0.9)))
            cells.append(Cell(rect: rect, uv: uv, color: SIMD4(0.86, 0.96, 0.88, 1)))
        }
        encoder.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(size.x), height: Double(size.y), znear: 0, zfar: 1))
        encoder.setRenderPipelineState(pipeline)
        cells.withUnsafeBytes { encoder.setVertexBytes($0.baseAddress!, length: $0.count, index: 0) }
        encoder.setFragmentTexture(texture, index: 0)
        var parameters = SIMD4<Float>(0, 0, 0, transparent ? 1 : 0)
        encoder.setFragmentBytes(&parameters, length: MemoryLayout<SIMD4<Float>>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: cells.count)
    }
}
