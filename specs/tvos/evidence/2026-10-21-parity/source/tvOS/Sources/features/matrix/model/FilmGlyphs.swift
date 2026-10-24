import CoreText
import Foundation

/// Reconstructed forms come from the bundled font; designed Latin/Cyrillic stay excluded.
enum FilmGlyphs {
    // Same classic repertoire as the macOS Matrix-Code option (MIT; see THIRD_PARTY_NOTICES.md).
    static let classic = Array("モエヤキオカ7ケサスz152ヨタワ4ネヌナ98ヒ0ホア3ウセ¦:\"꞊ミラリ╌ツテニハソ▪コシマムメー©*+<>|\u{E937}".unicodeScalars)

    static func scalars(font: CTFont, restored: Bool) -> [UnicodeScalar] {
        guard restored else { return classic }
        let characters = CTFontCopyCharacterSet(font)
        return (0xE001...0xF8FF).compactMap { code in
            CFCharacterSetIsCharacterMember(characters, UniChar(code)) ? UnicodeScalar(code) : nil
        }
    }

    static func uv(for variant: Int, inset: Float, side: Float, atlasWidth: Float, atlasHeight: Float, glyphCount: Int) -> SIMD4<Float> {
        let tile = variant % glyphCount
        let x = Float(tile % 8) * 64 + inset
        let y = Float(tile / 8) * 64 + inset
        return variant >= glyphCount
            ? SIMD4((x + side) / atlasWidth, y / atlasHeight, -side / atlasWidth, side / atlasHeight)
            : SIMD4(x / atlasWidth, y / atlasHeight, side / atlasWidth, side / atlasHeight)
    }
}
