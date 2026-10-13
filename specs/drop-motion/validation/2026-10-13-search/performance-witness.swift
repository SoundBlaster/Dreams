import Foundation
@main struct Bench { static func main() { for fraction in [0.1, 1.0] { var rain = MatrixSimulation(columnCount: 240, rows: 135, glyphCount: 57, density: 1); rain.setSearchFraction(fraction); let start=Date(); for frame in 0...300 { rain.advance(to: Double(frame)/60) }; print(fraction, Date().timeIntervalSince(start), rain.visibleSymbolCount, rain.searchingSymbolCount) } } }
