import Foundation

/// A fixed character grid. Only a column's writing cursor advances; cells never move.
struct MatrixSimulation {
    struct Symbol {
        var glyph = -1
        var writtenAt = -Double.infinity
        var changedAt = -Double.infinity
        var flashedAt = -Double.infinity
        var settledAt = -Double.infinity
        var ink: Float = 0
        var warmth: Float = 0
        var isGap = false
        var hold = 0.0
        var fade = 1.0
        // Activity can fade existing ink, but never reveal it again.
        var visibility: Float = 1

        func ink(brightnessSpread: Double) -> Float {
            let spread = brightnessSpread.isFinite ? min(1, max(0, brightnessSpread)) : 1
            // Keep the average exposure while adjusting differences between
            // cells. Stored random ink stays stable as the slider changes.
            return 0.45 + (ink - 0.45) * Float(spread)
        }
    }

    struct Search {
        let row: Int
        let writtenAt: Double
        let targetGlyph: Int
        let interval: Double
        var remaining: Int
    }

    struct Column {
        var cells: [Symbol]
        var nextRow = 0
        var headRow = -1
        var lastWrite = -Double.infinity
        var nextWrite: Double
        var nextMutation: Double
        var interval: Double
        var hold: Double
        var fade: Double
        var gapRemaining = 0
        var isEnabled = true
        var oneShot = false
        var search: Search?
        var generator: Generator
    }

    private(set) var columns: [Column] = []
    private(set) var time = 0.0
    let rows: Int
    private let glyphCount: Int
    private var random: UInt64
    private var density: Double
    private var fadeRows: Double

    mutating func setDensity(_ value: Double) {
        guard value.isFinite else { return }
        density = min(1, max(0, value))
    }

    mutating func setFadeRows(_ value: Double) {
        guard value.isFinite else { return }
        fadeRows = min(16, max(1, value))
    }

    init(columnCount: Int, rows: Int, glyphCount: Int, seed: UInt64 = 0xD2EA_5EED,
         density: Double = 0.8, fadeRows: Double = 1) {
        self.rows = rows
        self.glyphCount = glyphCount
        random = seed
        self.density = density.isFinite ? min(1, max(0, density)) : 0.8
        self.fadeRows = fadeRows.isFinite ? min(16, max(1, fadeRows)) : 1
        for index in 0..<columnCount {
            let delay = index == columnCount / 3 ? 0 : unit() * 2.8
            let interval = 1 / (18 + unit() * 24)
            // A moving packet of ink, shorter than the screen. Its rear follows
            // the writing cursor at the same speed; glyph positions stay fixed.
            let tailRows = Double(rows) * (0.3 + 0.7 * self.density) * (1 - unit() * 0.15 * (1 - self.density))
            let lifetime = tailRows * interval
            let fade = min(lifetime, self.fadeRows * interval)
            columns.append(Column(cells: Array(repeating: Symbol(), count: rows),
                nextWrite: delay, nextMutation: delay + 0.15 + unit() * 0.35,
                interval: interval, hold: lifetime - fade,
                fade: fade, generator: Generator(state: seed &+ UInt64(index) &* 7919)))
        }
    }

    /// Starts a single new top-to-bottom packet in response to an observed event.
    mutating func trigger(column index: Int, at time: Double) -> Double {
        columns[index].isEnabled = true
        columns[index].oneShot = true
        columns[index].nextRow = 0
        columns[index].gapRemaining = 0
        columns[index].nextWrite = time
        columns[index].search = nil
        columns[index].nextMutation = time + 0.2
        return Double(rows) * columns[index].interval + columns[index].hold + columns[index].fade + 0.2
    }

    mutating func finishPulse(column index: Int) {
        columns[index].oneShot = false
        columns[index].isEnabled = false
    }

    mutating func advance(to target: Double, visibility: [Float]? = nil, mutationRate: Double = 1) {
        let rate = mutationRate.isFinite ? min(3, max(1, mutationRate)) : 1
        guard target >= time, target.isFinite else { return }
        precondition(visibility == nil || visibility!.count == columns.count)
        for index in columns.indices {
            var column = columns[index]
            let visible = min(1, max(0, visibility?[index] ?? 1))
            if visible <= 0.002 {
                // Hidden columns must not keep typing and reappear prefilled.
                column.cells = Array(repeating: Symbol(), count: rows)
                column.isEnabled = false
                column.headRow = -1
                column.search = nil
                columns[index] = column
                continue
            }
            if !column.isEnabled {
                column.isEnabled = true
                column.nextRow = 0
                column.gapRemaining = 0
                column.lastWrite = -.infinity
                column.nextWrite = target + column.generator.unit() * 0.35
                column.nextMutation = column.nextWrite + 0.15 + column.generator.unit() * 0.35
            }
            // Process writing and single-cell mutation in timestamp order, independent of fps.
            while min(column.nextWrite, column.nextMutation) <= target {
                if column.nextWrite <= column.nextMutation {
                    let eventTime = column.nextWrite
                    let row = column.nextRow
                    if row == 0 {
                        // Existing cells retain their lifetime when a new packet
                        // uses changed tuning, including overlapping passes.
                        let lifetime = Double(rows) * (0.3 + 0.7 * density)
                            * (1 - column.generator.unit() * 0.15 * (1 - density)) * column.interval
                        column.fade = min(lifetime, fadeRows * column.interval)
                        column.hold = lifetime - column.fade
                    }
                    let ink = Float(0.14 + pow(column.generator.unit(), 1.3) * 0.7)
                    let warmth = Float(Int(column.generator.unit() * 5)) / 4
                    let glyph = Int(column.generator.unit() * Double(glyphCount))
                    if column.gapRemaining == 0 && column.generator.unit() < 0.06 * (1 - density) {
                        column.gapRemaining = 1 + Int(column.generator.unit() * 3)
                    }
                    let isGap = column.gapRemaining > 0
                    column.gapRemaining = max(0, column.gapRemaining - 1)
                    column.cells[row] = Symbol(glyph: glyph, writtenAt: eventTime,
                        changedAt: eventTime, ink: ink, warmth: warmth, isGap: isGap,
                        hold: column.hold, fade: column.fade)
                    if column.search?.row == row {
                        // A new packet owns this cell now; discard the old search.
                        column.search = nil
                        column.nextMutation = eventTime + (0.12 + column.generator.unit() * 0.5) / rate
                    }
                    column.headRow = row
                    column.lastWrite = eventTime
                    column.nextRow += 1
                    if column.nextRow == rows {
                        column.nextRow = 0
                        // At full density, wrap immediately. Lower densities
                        // leave a gap between successive packets.
                        let next = eventTime + column.interval
                            + (1 - density) * (column.hold + column.fade
                                + 0.25 + column.generator.unit() * 1.25)
                        column.nextWrite = column.oneShot ? .infinity : next
                    } else {
                        column.nextWrite = eventTime + column.interval
                    }
                } else {
                    let eventTime = column.nextMutation
                    if var search = column.search {
                        let cell = column.cells[search.row]
                        if cell.glyph >= 0 && !cell.isGap && cell.writtenAt == search.writtenAt
                            && eventTime - cell.writtenAt < cell.hold {
                            let final = search.remaining == 1
                            var replacement = search.targetGlyph
                            if !final {
                                replacement = (cell.glyph + 1 + Int(column.generator.unit()
                                    * Double(glyphCount - 1))) % glyphCount
                                // Reserve the selected combination for the final step.
                                if replacement == search.targetGlyph && glyphCount > 2 {
                                    repeat { replacement = (replacement + 1) % glyphCount }
                                    while replacement == cell.glyph || replacement == search.targetGlyph
                                }
                            }
                            column.cells[search.row].glyph = replacement
                            column.cells[search.row].changedAt = eventTime
                            search.remaining -= 1
                            if final {
                                column.cells[search.row].settledAt = eventTime
                                // Settling a search keeps its ordinary green ink.
                                // Preserve the random sequence for the rest of the rain.
                                _ = column.generator.unit()
                                column.search = nil
                            } else {
                                column.search = search
                                column.nextMutation = eventTime + search.interval / rate
                                continue
                            }
                        } else {
                            // Fading or overwritten ink cannot be kept alive by a search.
                            column.search = nil
                        }
                        column.nextMutation = eventTime + (0.12 + column.generator.unit() * 0.5) / rate
                        continue
                    }
                    let candidates = column.cells.indices.filter { row in
                        let cell = column.cells[row]
                        return cell.glyph >= 0 && !cell.isGap && row != column.headRow
                            && eventTime - cell.writtenAt < cell.hold
                            && eventTime - cell.settledAt >= 0.8
                    }
                    if !candidates.isEmpty {
                        let row = candidates[Int(column.generator.unit() * Double(candidates.count))]
                        let old = column.cells[row].glyph
                        let replacement = (old + 1 + Int(column.generator.unit() * Double(glyphCount - 1))) % glyphCount
                        column.cells[row].glyph = replacement
                        column.cells[row].changedAt = eventTime
                        if column.generator.unit() < 0.65 {
                            let target = (replacement + 1 + Int(column.generator.unit()
                                * Double(glyphCount - 1))) % glyphCount
                            let interval = 0.035 + column.generator.unit() * 0.03
                            column.search = Search(row: row, writtenAt: column.cells[row].writtenAt,
                                targetGlyph: target, interval: interval,
                                remaining: 3 + Int(column.generator.unit() * 5))
                            column.nextMutation = eventTime + interval / rate
                            continue
                        }
                        column.cells[row].settledAt = eventTime
                        if column.generator.unit() < 0.2 { column.cells[row].flashedAt = eventTime }
                    }
                    column.nextMutation = eventTime + (0.12 + column.generator.unit() * 0.5) / rate
                }
            }
            for row in column.cells.indices {
                column.cells[row].visibility = min(column.cells[row].visibility, visible)
                if target - column.cells[row].writtenAt >= column.cells[row].hold + column.cells[row].fade {
                    // Only a future cursor write can replace expired ink.
                    column.cells[row] = Symbol()
                }
            }
            columns[index] = column
        }
        time = target
    }

    func opacity(column: Int, row: Int) -> Float {
        let c = columns[column]
        let cell = c.cells[row]
        guard cell.glyph >= 0 else { return 0 }
        let age = time - cell.writtenAt
        return Float(max(0, min(1, 1 - (age - cell.hold) / cell.fade)))
    }

    func headIntensity(column: Int, row: Int) -> Float {
        let c = columns[column]
        guard c.headRow == row else { return 0 }
        return Float(max(0, 1 - (time - c.lastWrite) / 0.11))
    }

    private mutating func unit() -> Double {
        random &+= 0x9E3779B97F4A7C15
        var value = random
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return Double((value ^ (value >> 31)) >> 11) / 9_007_199_254_740_992
    }
}

extension MatrixSimulation {
    struct Generator {
        var state: UInt64
        mutating func unit() -> Double {
            state &+= 0x9E3779B97F4A7C15
            var value = state
            value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
            value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
            return Double((value ^ (value >> 31)) >> 11) / 9_007_199_254_740_992
        }
    }
}
