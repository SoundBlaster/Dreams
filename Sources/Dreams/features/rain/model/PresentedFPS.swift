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
