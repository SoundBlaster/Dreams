import Foundation

@main struct Benchmark {
    static func main() {
        for count in [100, 190] {
            for run in 0..<5 {
                var model = MatrixSimulation(columnCount: count, rows: 72, glyphCount: 57, seed: 17, density: 0.82)
                model.setSearchFraction(0.03)
                model.setDeceleration(.init(enabled: true, acceleration: -12))
                let start = ProcessInfo.processInfo.systemUptime
                for frame in 0..<1800 { model.advance(to: Double(frame) / 50) }
                let elapsed = ProcessInfo.processInfo.systemUptime - start
                let checksum = model.columns.flatMap(\.cells).reduce(0) { $0 &+ $1.glyph }
                print("columns=\(count) run=\(run) seconds=\(elapsed) checksum=\(checksum)")
            }
        }
    }
}
