import Foundation

/// Fully specified input, independent of the owner's UserDefaults and mailbox.
struct RainPerformanceScenario: Codable, Equatable {
    let name: String
    let warmupSeconds: Double
    let measureSeconds: Double
    let drawableWidth: Int
    let drawableHeight: Int
    let referenceWidth: Int
    let referenceHeight: Int
    let columns: Int
    let density: Double
    let searchFraction: Double
    let glow: Double
    let speed: Double
    let fadeRows: Double
    let pulseStrength: Double
    let brightnessSpread: Double
    let restoredGlyphs: Bool
    let transparent: Bool

    func validate() throws {
        guard !name.isEmpty, name.count <= 80,
              warmupSeconds.isFinite, (0...120).contains(warmupSeconds),
              measureSeconds.isFinite, (1...300).contains(measureSeconds),
              (64...4096).contains(drawableWidth), (64...4096).contains(drawableHeight),
              (64...4096).contains(referenceWidth), (64...4096).contains(referenceHeight),
              columns == 0 || (24...240).contains(columns),
              density.isFinite, (0...1).contains(density),
              searchFraction.isFinite, (0...1).contains(searchFraction),
              glow.isFinite, (0...3).contains(glow), speed.isFinite, (0.25...3).contains(speed),
              fadeRows.isFinite, (1...16).contains(fadeRows),
              pulseStrength.isFinite, (0...1).contains(pulseStrength),
              brightnessSpread.isFinite, (0...1).contains(brightnessSpread) else {
            throw DreamsError.unavailable("Invalid or unbounded performance scenario.")
        }
        let aspect = Double(referenceWidth) / Double(referenceHeight)
        let gridColumns = columns == 0 ? max(24, Int(aspect * 72)) : columns
        let gridRows = columns == 0 ? 72 : max(8, Int((Double(columns) / aspect).rounded()))
        guard gridColumns <= 65_536 / gridRows else {
            throw DreamsError.unavailable("Performance scenario grid exceeds 65536 cells.")
        }
    }
}
