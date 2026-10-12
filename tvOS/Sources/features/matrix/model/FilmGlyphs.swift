import Foundation

/// Only the 28 reconstructed film forms, never the font's designed Latin or Cyrillic.
enum FilmGlyphs {
    static let scalars = (0xE001...0xE01C).compactMap(UnicodeScalar.init)
    static let variantCount = scalars.count * 2

    static func tile(for variant: Int) -> Int { variant % scalars.count }
    static func isMirrored(_ variant: Int) -> Bool { variant >= scalars.count }

    static func uv(for variant: Int, inset: Float, side: Float, atlasWidth: Float, atlasHeight: Float) -> SIMD4<Float> {
        let tile = tile(for: variant)
        let x = Float(tile % 8) * 64 + inset
        let y = Float(tile / 8) * 64 + inset
        return isMirrored(variant)
            ? SIMD4((x + side) / atlasWidth, y / atlasHeight, -side / atlasWidth, side / atlasHeight)
            : SIMD4(x / atlasWidth, y / atlasHeight, side / atlasWidth, side / atlasHeight)
    }
}
