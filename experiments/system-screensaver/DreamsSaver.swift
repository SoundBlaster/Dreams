import AppKit
import ScreenSaver

// A deliberately isolated lifecycle probe, not the production Metal renderer.
@objc(DreamsSystemSaverView)
final class DreamsSystemSaverView: ScreenSaverView {
    private var columns: [Column] = []
    private var lastTime: TimeInterval?
    private let glyphs = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZｱｲｳｴｵｶｷｸｹｺ")
    private let cell: CGFloat = 20

    private struct Column {
        var head: CGFloat
        var speed: CGFloat
        var symbols: [String]
    }

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / 30.0
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        animationTimeInterval = 1.0 / 30.0
    }

    override func startAnimation() {
        super.startAnimation()
        lastTime = nil
    }

    override func stopAnimation() {
        lastTime = nil
        super.stopAnimation()
    }

    override func animateOneFrame() {
        let now = ProcessInfo.processInfo.systemUptime
        let delta = min(now - (lastTime ?? now), 0.1)
        lastTime = now
        let count = max(1, Int(ceil(bounds.width / cell)))
        if columns.count != count {
            columns = (0..<count).map { _ in
                Column(head: CGFloat.random(in: 0...max(bounds.height, 1)),
                       speed: CGFloat.random(in: 35...95),
                       symbols: (0..<12).map { _ in String(glyphs.randomElement()!) })
            }
        }
        for index in columns.indices {
            columns[index].head -= columns[index].speed * delta
            if columns[index].head < -cell * 12 {
                columns[index].head = bounds.height + cell
            }
        }
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        bounds.fill()
        let font = NSFont.monospacedSystemFont(ofSize: 16, weight: .regular)
        for (index, column) in columns.enumerated() {
            for (row, symbol) in column.symbols.enumerated() {
                let alpha = CGFloat(1 - Double(row) / Double(column.symbols.count))
                let color = NSColor(calibratedRed: 0.1, green: 1, blue: 0.35, alpha: alpha)
                symbol.draw(at: NSPoint(x: CGFloat(index) * cell, y: column.head + CGFloat(row) * cell),
                            withAttributes: [.font: font, .foregroundColor: color])
            }
        }
    }
}
