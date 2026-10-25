import Foundation
import os

/// Counts observed frame intervals, never CPU draw calls. Each renderer owns its own window.
final class PresentedFPS: Sendable {
    private struct State {
        var generation = 0
        var start: Double?
        var last: Double?
        var intervals = 0
        var value: Int?
    }
    private let state = OSAllocatedUnfairLock(initialState: State())

    func reset() {
        state.withLock { $0 = State(generation: $0.generation &+ 1) }
    }

    var generation: Int { state.withLock { $0.generation } }
    var value: Int? { state.withLock { $0.value } }

    func presented(at time: Double, generation: Int) {
        state.withLock { state in
            guard generation == state.generation, time.isFinite, time > 0,
                  time > (state.last ?? 0) else { return }
            state.last = time
            guard let start = state.start else { state.start = time; return }
            state.intervals += 1
            let elapsed = time - start
            if elapsed >= 1 {
                state.value = min(999, max(0, Int((Double(state.intervals) / elapsed).rounded())))
                state.start = time
                state.intervals = 0
            }
        }
    }
}

/// Three reserved cells, inset one row/column from the visible rain grid edge.
struct FPSGrid: Equatable {
    static let glyphWidth: Float = 1.30 * (22.0 / 30.0) / (38.0 / 46.0)
    static let glyphHeight: Float = 1.32
    let columns: Int
    let rows: Int
    let row: Int
    let endColumn: Int
    let glyphScale: Float

    init?(columns: Int, rows: Int, visibleColumns: Int? = nil, row: Int = 1, glyphScale: Float = 1) {
        let visible = min(columns, visibleColumns ?? columns)
        guard visible >= 5, rows >= 3, row >= 0, row < rows,
              glyphScale.isFinite, glyphScale > 0 else { return nil }
        self.columns = columns
        self.rows = rows
        self.row = row
        endColumn = visible - 1
        self.glyphScale = glyphScale
    }

    func contains(column: Int, row: Int) -> Bool {
        row == self.row && (endColumn - 3..<endColumn).contains(column)
    }

    func rect(column: Int) -> SIMD4<Float> {
        let width = Self.glyphWidth * glyphScale, height = Self.glyphHeight * glyphScale
        return SIMD4((Float(column) + (1 - width) / 2) / Float(columns),
                     (Float(row) + (1 - height) / 2) / Float(rows), width / Float(columns), height / Float(rows))
    }
}
