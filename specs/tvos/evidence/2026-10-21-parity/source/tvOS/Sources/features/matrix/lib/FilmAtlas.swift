import CoreText
import Metal
import UIKit

enum MatrixRenderError: Error {
    case metalUnavailable, resource(String), shader, bitmap, texture, missingGlyph
}

@MainActor
struct FilmAtlas {
    let core: MTLTexture
    let glow: MTLTexture
    static let width = 512
    let height: Int
    let glyphCount: Int
    var variantCount: Int { glyphCount * 2 }

    init(device: MTLDevice, restored: Bool = true) throws {
        let resource = restored ? "DreamsMatrix" : "Matrix-Code"
        guard let url = Bundle.main.url(forResource: resource, withExtension: "ttf") else {
            throw MatrixRenderError.resource(resource + ".ttf")
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        let name = restored ? "DreamsMatrix-Regular" : "Matrix-Code"
        let font = CTFontCreateWithName(name as CFString, 26, nil)
        guard CTFontCopyPostScriptName(font) as String == name else { throw MatrixRenderError.missingGlyph }
        let scalars = FilmGlyphs.scalars(font: font, restored: restored)
        guard !scalars.isEmpty else { throw MatrixRenderError.missingGlyph }
        glyphCount = scalars.count
        height = ((glyphCount + 7) / 8) * 64
        var pixels = [UInt8](repeating: 0, count: Self.width * height)
        var haze = pixels
        for (index, scalar) in scalars.enumerated() {
            let tile = try Self.rasterize(String(scalar), font: font)
            let blurred = Self.blur(tile, sigma: 3)
            let wide = Self.blur(tile, sigma: 6)
            for row in 0..<64 {
                for column in 0..<64 {
                    let source = row * 64 + column
                    let target = (index / 8 * 64 + row) * Self.width + index % 8 * 64 + column
                    pixels[target] = tile[source]
                    haze[target] = UInt8(min(255, (blurred[source] * 0.4 + wide[source] * 0.6) * 2.2))
                }
            }
        }
        core = try Self.texture(device: device, width: Self.width, height: height, pixels: pixels)
        glow = try Self.texture(device: device, width: Self.width, height: height, pixels: haze)
    }

    static func texture(device: MTLDevice, width: Int, height: Int, pixels: [UInt8]) throws -> MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Unorm, width: width,
                                                                  height: height, mipmapped: false)
        descriptor.usage = .shaderRead
        guard let texture = device.makeTexture(descriptor: descriptor) else { throw MatrixRenderError.texture }
        pixels.withUnsafeBytes { bytes in
            texture.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0,
                            withBytes: bytes.baseAddress!, bytesPerRow: width)
        }
        return texture
    }

    private static func rasterize(_ text: String, font: CTFont) throws -> [UInt8] {
        var tile = [UInt8](repeating: 0, count: 64 * 64)
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): UIColor.white.cgColor
        ]))
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        let lineWidth = CTLineGetTypographicBounds(line, &ascent, &descent, nil)
        let rendered = tile.withUnsafeMutableBytes { bytes -> Bool in
            guard let context = CGContext(data: bytes.baseAddress, width: 64, height: 64,
                                          bitsPerComponent: 8, bytesPerRow: 64, space: CGColorSpaceCreateDeviceGray(),
                                          bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return false }
            context.textPosition = CGPoint(x: (64 - lineWidth) / 2, y: (64 - ascent - descent) / 2 + descent)
            CTLineDraw(line, context)
            return true
        }
        guard rendered else { throw MatrixRenderError.bitmap }
        return tile
    }

    private static func blur(_ pixels: [UInt8], sigma: Double) -> [Double] {
        let radius = Int(ceil(sigma * 2.5))
        var kernel = (-radius...radius).map { exp(-Double($0 * $0) / (2 * sigma * sigma)) }
        let total = kernel.reduce(0, +)
        kernel = kernel.map { $0 / total }
        var horizontal = [Double](repeating: 0, count: pixels.count)
        var output = horizontal
        for row in 0..<64 {
            for column in 0..<64 {
                for offset in -radius...radius where (0..<64).contains(column + offset) {
                    horizontal[row * 64 + column] += Double(pixels[row * 64 + column + offset]) * kernel[offset + radius]
                }
            }
        }
        for row in 0..<64 {
            for column in 0..<64 {
                for offset in -radius...radius where (0..<64).contains(row + offset) {
                    output[row * 64 + column] += horizontal[(row + offset) * 64 + column] * kernel[offset + radius]
                }
            }
        }
        return output
    }
}
