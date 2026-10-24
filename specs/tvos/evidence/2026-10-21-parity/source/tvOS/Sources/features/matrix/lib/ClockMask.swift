import CoreText
import UIKit

struct ClockMask {
    let width: Int
    let height: Int
    let pixels: [UInt8]
    let occupiedWidth: Double
    let occupiedHeight: Double

    /// A glyph is a single clock pixel: its entire outline receives one exposure.
    func illuminates(center: SIMD2<Float>) -> Bool {
        guard center.x >= 0, center.x < 1, center.y >= 0, center.y < 1 else { return false }
        let x = Int(center.x * Float(width))
        let y = Int(center.y * Float(height))
        return pixels[y * width + x] >= 128
    }

    static func minuteKey(at date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    @MainActor
    init(time: String, aspect: Double, typeface: ClockTypeface = .system, size: Double = 1) throws {
        let width = 1024
        let height = max(256, Int(Double(width) / max(1, aspect)))
        self.width = width
        self.height = height
        var bitmap = [UInt8](repeating: 0, count: width * height)
        let base = UIFont.monospacedDigitSystemFont(ofSize: CGFloat(width) * 0.245 * size, weight: .bold)
        let design: UIFontDescriptor.SystemDesign = switch typeface {
        case .system: .default
        case .rounded: .rounded
        case .monospaced: .monospaced
        }
        let font = base.fontDescriptor.withDesign(design).map { UIFont(descriptor: $0, size: base.pointSize) } ?? base
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: time, attributes: [
            .font: font, .foregroundColor: UIColor.white
        ]))
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        let lineWidth = CTLineGetTypographicBounds(line, &ascent, &descent, nil)
        occupiedWidth = lineWidth / Double(width)
        occupiedHeight = Double(ascent + descent) / Double(height)
        let rendered = bitmap.withUnsafeMutableBytes { bytes -> Bool in
            guard let context = CGContext(data: bytes.baseAddress, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: width,
                                          space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
                return false
            }
            // Bitmap scanlines and the rain grid both start at the top row.
            context.textPosition = CGPoint(x: (Double(width) - lineWidth) / 2,
                                           y: (CGFloat(height) - ascent - descent) / 2 + descent)
            CTLineDraw(line, context)
            return true
        }
        guard rendered else { throw MatrixRenderError.bitmap }
        pixels = bitmap
    }
}
