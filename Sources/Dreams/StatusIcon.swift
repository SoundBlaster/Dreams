import AppKit
import CoreText

/// The menu bar icon: the restored film glyph G05 (U+E005 of DreamsMatrix), drawn from its outline as a
/// monochrome template image, so the system tints it for light and dark menu bars.
enum StatusIcon {
    static let glyphCodePoint: UniChar = 0xE005

    static func image(fontURL: URL? = Bundle.module.url(forResource: "DreamsMatrix", withExtension: "ttf"),
                      size: CGFloat = 18, inset: CGFloat = 1.5) -> NSImage? {
        if let fontURL { CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil) }
        let font = CTFontCreateWithName("DreamsMatrix-Regular" as CFString, 100, nil)
        var code = glyphCodePoint
        var glyph = CGGlyph()
        guard CTFontGetGlyphsForCharacters(font, &code, &glyph, 1), glyph != 0,
              let outline = CTFontCreatePathForGlyph(font, glyph, nil), !outline.boundingBox.isEmpty else { return nil }
        let box = outline.boundingBox
        let target = size - 2 * inset
        let scale = target / max(box.width, box.height)
        var fit = CGAffineTransform(translationX: -box.midX, y: -box.midY)
            .concatenating(CGAffineTransform(scaleX: scale, y: scale))
            .concatenating(CGAffineTransform(translationX: size / 2, y: size / 2))
        guard let path = outline.copy(using: &fit) else { return nil }
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.setFillColor(NSColor.black.cgColor)
            context.addPath(path)
            context.fillPath()
            return true
        }
        image.isTemplate = true
        return image
    }
}
