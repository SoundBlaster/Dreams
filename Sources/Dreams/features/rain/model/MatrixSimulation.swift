import Foundation

/// A fixed character grid. Only a column's writing cursor advances; cells never move.
struct MatrixSimulation {
    private static let tailIntervalScale = 1.6

    struct Deceleration: Equatable {
        static let defaultAcceleration = -12.0
        static let minimumAcceleration = -120.0
        static let terminalSpeedRatio = 0.2
        let enabled: Bool
        let acceleration: Double

        init(enabled: Bool = false, acceleration: Double = Self.defaultAcceleration) {
            self.enabled = enabled
            self.acceleration = acceleration.isFinite ? min(0, max(Self.minimumAcceleration, acceleration))
                : Self.defaultAcceleration
        }

        func motion(interval: Double) -> Motion? {
            guard enabled, acceleration < 0 else { return nil }
            return Motion(initialSpeed: 1 / interval, acceleration: acceleration)
        }
    }

    /// Analytic row-arrival times: constant negative acceleration, then a positive speed floor.
    struct Motion {
        let initialSpeed: Double
        let acceleration: Double
        var terminalSpeed: Double { initialSpeed * Deceleration.terminalSpeedRatio }
        var brakingTime: Double { (initialSpeed - terminalSpeed) / -acceleration }
        var brakingDistance: Double { (initialSpeed + terminalSpeed) * brakingTime / 2 }

        func arrival(at distance: Double) -> Double {
            guard distance > 0 else { return 0 }
            if distance >= brakingDistance {
                return brakingTime + (distance - brakingDistance) / terminalSpeed
            }
            // Stable quadratic root, including arbitrarily weak braking near zero acceleration.
            let speed = sqrt(max(0, initialSpeed * initialSpeed + 2 * acceleration * distance))
            return 2 * distance / (initialSpeed + speed)
        }
    }

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
        var nextTrial: Double
    }

    struct Column {
        var cells: [Symbol]
        var nextRow = 0
        var headRow = -1
        var lastWrite = -Double.infinity
        var nextWrite: Double
        var nextMutation: Double
        var interval: Double
        var packetStartedAt = 0.0
        var motion: Motion?
        // The writing head outruns the dissolving rear; glyphs themselves stay fixed.
        var tailInterval: Double { interval * MatrixSimulation.tailIntervalScale }
        var hold: Double
        var fade: Double
        var gapRemaining = 0
        var isEnabled = true
        var oneShot = false
        // Dynamic occupancy: at the end of every pass (and at start) a column draws a fresh
        // `rank`; if it exceeds the coverage the column rests for a pass or so, then draws again.
        var gated = false
        var resting = false
        var rank = 0.0
        var restUntil = 0.0
        var searches: [Int: Search] = [:]
        var nextExpiry = Double.infinity
        var generator: Generator
    }

    private(set) var columns: [Column] = []
    private(set) var time = 0.0
    let rows: Int
    private let glyphCount: Int
    private var random: UInt64
    private var density: Double
    private var fadeRows: Double
    private var deceleration: Deceleration
    private var searchFraction = 0.1
    private var searchGenerator = Generator(state: 0x5EA2_C4)
    private struct Position: Hashable { let column: Int; let row: Int }
    private var available: [Position] = []
    private var availableIndex: [Position: Int] = [:]
    var searchingSymbolCount: Int { columns.reduce(0) { $0 + $1.searches.count } }
    var visibleSymbolCount: Int { available.count + searchingSymbolCount }

    mutating func setSearchFraction(_ value: Double) {
        guard value.isFinite else { return }
        searchFraction = min(1, max(0, value))
    }

    mutating func setDeceleration(_ value: Deceleration) {
        deceleration = value
    }

    mutating func setDensity(_ value: Double) {
        guard value.isFinite else { return }
        density = min(1, max(0, value))
    }

    mutating func setFadeRows(_ value: Double) {
        guard value.isFinite else { return }
        fadeRows = min(16, max(1, value))
    }

    init(columnCount: Int, rows: Int, glyphCount: Int, seed: UInt64 = 0xD2EA_5EED,
         density: Double = 0.8, fadeRows: Double = 1, deceleration: Deceleration = Deceleration()) {
        self.rows = rows
        self.deceleration = deceleration
        self.glyphCount = glyphCount
        random = seed
        self.density = density.isFinite ? min(1, max(0, density)) : 0.8
        self.fadeRows = fadeRows.isFinite ? min(16, max(1, fadeRows)) : 1
        for index in 0..<columnCount {
            let delay = index == columnCount / 3 ? 0 : unit() * 2.8
            let interval = 1 / (18 + unit() * 24)
            // A short initial trace stretches as the faster head writes downward.
            let initialRows = Double(rows) * (0.1 + 0.9 * self.density) * (1 - unit() * 0.15 * (1 - self.density))
            let tailInterval = interval * Self.tailIntervalScale
            let lifetime = max(tailInterval, initialRows * interval)
            let fade = min(lifetime, self.fadeRows * tailInterval)
            columns.append(Column(cells: Array(repeating: Symbol(), count: rows),
                nextWrite: delay, nextMutation: delay + 0.15 + unit() * 0.35,
                interval: interval, hold: lifetime - fade,
                fade: fade, generator: Generator(state: seed &+ UInt64(index) &* 7919)))
        }
        for index in columns.indices { columns[index].nextMutation = .infinity }
    }

    /// Starts a single new top-to-bottom packet in response to an observed event.
    mutating func trigger(column index: Int, at time: Double) -> Double {
        columns[index].isEnabled = true
        columns[index].oneShot = true
        columns[index].nextRow = 0
        columns[index].gapRemaining = 0
        columns[index].nextWrite = time
        for row in columns[index].searches.keys.sorted() {
            columns[index].searches.removeValue(forKey: row)
            addAvailable(Position(column: index, row: row))
        }
        columns[index].nextMutation = .infinity
        // Bound the whole stretched trace, including its slow rear after the head
        // leaves the screen. Row zero will draw the packet's actual lifetime.
        let column = columns[index]
        let motion = deceleration.motion(interval: column.interval)
        let passTime = motion?.arrival(at: Double(rows)) ?? Double(rows) * column.interval
        let initialLifetime = motion == nil
            ? max(column.tailInterval, Double(rows) * (0.1 + 0.9 * density) * column.interval)
            : max(column.tailInterval, passTime * (0.1 + 0.9 * density))
        let headTime = motion?.arrival(at: Double(rows - 1)) ?? Double(rows - 1) * column.interval
        let rearTime = motion == nil ? Double(rows - 1) * column.tailInterval : headTime * Self.tailIntervalScale
        return rearTime + initialLifetime + 0.2
    }

    mutating func finishPulse(column index: Int) {
        columns[index].oneShot = false
        columns[index].isEnabled = false
    }

    /// `searchFraction` is the simultaneous share of live, non-gap cells, including fading ink.
    /// Coverage gates columns; hidden columns are cleared and cannot keep a search alive.
    mutating func advance(to target: Double, visibility: [Float]? = nil, coverage: Double = 1,
                          mutationRate: Double = 1) {
        let coverage = coverage.isFinite ? min(1, max(0, coverage)) : 1
        let rate = mutationRate.isFinite ? min(3, max(1, mutationRate)) : 1
        guard target >= time, target.isFinite else { return }
        precondition(visibility == nil || visibility!.count == columns.count)
        for index in columns.indices {
            let visible = min(1, max(0, visibility?[index] ?? 1))
            if visible <= 0.002 {
                // Hidden columns must not keep typing and reappear prefilled.
                for row in columns[index].cells.indices { removePosition(Position(column: index, row: row)) }
                columns[index].cells = Array(repeating: Symbol(), count: rows)
                columns[index].isEnabled = false
                columns[index].headRow = -1
                columns[index].nextWrite = .infinity
                columns[index].nextMutation = .infinity
                columns[index].nextExpiry = .infinity
                continue
            }
            var column = columns[index]
            for row in column.cells.indices { column.cells[row].visibility = min(column.cells[row].visibility, visible) }
            if !column.isEnabled {
                column.isEnabled = true
                column.nextRow = 0
                column.gapRemaining = 0
                column.lastWrite = -.infinity
                column.nextWrite = target + column.generator.unit() * 0.35
                _ = column.generator.unit()
                column.nextMutation = column.searches.values.map(\.nextTrial).min() ?? .infinity
                column.gated = false
                column.resting = false
            }
            if !column.oneShot {
                if !column.gated {
                    column.gated = true
                    if coverage < 1 {
                        column.rank = column.generator.unit()
                        if column.rank > coverage {
                            column.resting = true
                            column.restUntil = target + column.generator.unit() * Double(rows) * column.interval
                            column.nextWrite = .infinity
                        }
                    }
                }
                while column.resting {
                    if column.rank <= coverage {
                        // More coverage (a surge) wakes the resting columns that now fit.
                        column.resting = false
                        column.nextRow = 0
                        column.gapRemaining = 0
                        column.nextWrite = target + column.generator.unit() * 0.35
                        break
                    }
                    guard target >= column.restUntil else { break }
                    column.rank = column.generator.unit()
                    column.restUntil += Double(rows) * column.interval * (0.5 + column.generator.unit())
                }
            }
            columns[index] = column
        }
        maintainSearchShare(at: time, rate: rate)
        // One global timestamp order keeps pool selection independent of frame subdivision.
        while let index = columns.indices.min(by: { nextEvent(in: $0) < nextEvent(in: $1) }),
              nextEvent(in: index) <= target {
            let eventTime = nextEvent(in: index)
            if columns[index].nextWrite <= columns[index].nextMutation
                && columns[index].nextWrite <= columns[index].nextExpiry {
                writeNext(in: index, visibility: min(1, max(0, visibility?[index] ?? 1)), coverage: coverage)
            } else if columns[index].nextExpiry <= columns[index].nextMutation {
                expireCells(in: index, at: eventTime)
            } else {
                advanceSearch(in: index, at: eventTime, rate: rate)
            }
            maintainSearchShare(at: eventTime, rate: rate)
        }
        time = target
    }

    private func nextEvent(in index: Int) -> Double {
        min(columns[index].nextWrite, columns[index].nextMutation, columns[index].nextExpiry)
    }

    private mutating func writeNext(in index: Int, visibility visible: Float, coverage: Double) {
        let position = Position(column: index, row: columns[index].nextRow)
        removePosition(position)
        var column = columns[index]
        let eventTime = column.nextWrite
        let row = column.nextRow
        if row == 0 {
            // Existing cells retain their lifetime when a new packet
            // uses changed tuning, including overlapping passes.
            column.packetStartedAt = eventTime
            column.motion = deceleration.motion(interval: column.interval)
            let variation = 1 - column.generator.unit() * 0.15 * (1 - density)
            let lifetime: Double
            if let motion = column.motion {
                lifetime = max(column.tailInterval, motion.arrival(at: Double(rows))
                    * (0.1 + 0.9 * density) * variation)
            } else {
                lifetime = max(column.tailInterval, Double(rows) * (0.1 + 0.9 * density)
                    * variation * column.interval)
            }
            column.fade = min(lifetime, fadeRows * column.tailInterval)
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
        let stretch = column.motion == nil ? Double(row) * (column.tailInterval - column.interval)
            : (eventTime - column.packetStartedAt) * (Self.tailIntervalScale - 1)
        column.cells[row] = Symbol(glyph: glyph, writtenAt: eventTime,
            changedAt: eventTime, ink: ink, warmth: warmth, isGap: isGap,
            hold: column.hold + stretch, fade: column.fade, visibility: visible)
        column.headRow = row
        column.lastWrite = eventTime
        column.nextRow += 1
        if column.nextRow == rows {
            column.nextRow = 0
            // At full density, wrap immediately. Lower densities
            // leave a gap between successive packets.
            let step = column.motion.map {
                $0.arrival(at: Double(rows)) - $0.arrival(at: Double(rows - 1))
            } ?? column.interval
            let next = eventTime + step
                + (1 - density) * (column.cells[row].hold + column.cells[row].fade
                    + 0.25 + column.generator.unit() * 1.25)
            if column.oneShot {
                column.nextWrite = .infinity
            } else if coverage < 1 {
                column.rank = column.generator.unit()
                if column.rank > coverage {
                    column.resting = true
                    column.restUntil = next + Double(rows) * column.interval * (0.5 + column.generator.unit())
                    column.nextWrite = .infinity
                } else {
                    column.nextWrite = next
                }
            } else {
                column.nextWrite = next
            }
        } else {
            if let motion = column.motion {
                column.nextWrite = column.packetStartedAt + motion.arrival(at: Double(column.nextRow))
            } else {
                column.nextWrite = eventTime + column.interval
            }
        }
        column.nextExpiry = column.cells.filter { $0.glyph >= 0 }
            .map { $0.writtenAt + $0.hold + $0.fade }.min() ?? .infinity
        columns[index] = column
        if !column.cells[position.row].isGap { addAvailable(position) }
    }

    private mutating func expireCells(in index: Int, at time: Double) {
        for row in columns[index].cells.indices {
            let cell = columns[index].cells[row]
            if cell.glyph >= 0 && time >= cell.writtenAt + cell.hold + cell.fade {
                removePosition(Position(column: index, row: row))
                columns[index].cells[row] = Symbol()
            }
        }
        columns[index].nextExpiry = columns[index].cells.filter { $0.glyph >= 0 }
            .map { $0.writtenAt + $0.hold + $0.fade }.min() ?? .infinity
    }

    private mutating func addAvailable(_ position: Position) {
        guard availableIndex[position] == nil else { return }
        availableIndex[position] = available.count
        available.append(position)
    }

    private mutating func removeAvailable(_ position: Position) {
        guard let index = availableIndex.removeValue(forKey: position) else { return }
        let last = available.removeLast()
        if index < available.count { available[index] = last; availableIndex[last] = index }
    }

    private mutating func refreshMutationTime(in index: Int) {
        columns[index].nextMutation = columns[index].searches.values.map(\.nextTrial).min() ?? .infinity
    }

    private mutating func removePosition(_ position: Position) {
        removeAvailable(position)
        columns[position.column].searches.removeValue(forKey: position.row)
        refreshMutationTime(in: position.column)
    }

    private mutating func maintainSearchShare(at time: Double, rate: Double) {
        let target = Int(ceil(Double(visibleSymbolCount) * searchFraction))
        var active = searchingSymbolCount
        if active > target {
            for index in columns.indices {
                for row in columns[index].searches.keys.sorted() where active > target {
                    columns[index].searches.removeValue(forKey: row)
                    addAvailable(Position(column: index, row: row))
                    active -= 1
                }
                refreshMutationTime(in: index)
            }
        }
        guard glyphCount > 1 else { return }
        while active < target, !available.isEmpty {
            let position = available[Int(searchGenerator.unit() * Double(available.count))]
            removeAvailable(position)
            let cell = columns[position.column].cells[position.row]
            let replacement = (cell.glyph + 1 + Int(searchGenerator.unit() * Double(glyphCount - 1))) % glyphCount
            let targetGlyph = (replacement + 1 + Int(searchGenerator.unit() * Double(glyphCount - 1))) % glyphCount
            let interval = 0.035 + searchGenerator.unit() * 0.03
            columns[position.column].cells[position.row].glyph = replacement
            columns[position.column].cells[position.row].changedAt = time
            columns[position.column].searches[position.row] = Search(row: position.row, writtenAt: cell.writtenAt,
                targetGlyph: targetGlyph, interval: interval, remaining: 3 + Int(searchGenerator.unit() * 5),
                nextTrial: time + interval / rate)
            refreshMutationTime(in: position.column)
            active += 1
        }
    }

    private mutating func advanceSearch(in index: Int, at time: Double, rate: Double) {
        guard var search = columns[index].searches.values.min(by: {
            $0.nextTrial == $1.nextTrial ? $0.row < $1.row : $0.nextTrial < $1.nextTrial
        }) else { columns[index].nextMutation = .infinity; return }
        let cell = columns[index].cells[search.row]
        guard cell.glyph >= 0, !cell.isGap, cell.writtenAt == search.writtenAt,
              time < cell.writtenAt + cell.hold + cell.fade else {
            columns[index].searches.removeValue(forKey: search.row)
            refreshMutationTime(in: index)
            return
        }
        let final = search.remaining == 1
        var replacement = search.targetGlyph
        if !final {
            replacement = (cell.glyph + 1 + Int(searchGenerator.unit() * Double(glyphCount - 1))) % glyphCount
            if replacement == search.targetGlyph && glyphCount > 2 {
                repeat { replacement = (replacement + 1) % glyphCount }
                while replacement == cell.glyph || replacement == search.targetGlyph
            }
        }
        columns[index].cells[search.row].glyph = replacement
        columns[index].cells[search.row].changedAt = time
        search.remaining -= 1
        if final {
            columns[index].cells[search.row].settledAt = time
            columns[index].searches.removeValue(forKey: search.row)
            addAvailable(Position(column: index, row: search.row))
        } else {
            search.nextTrial = time + search.interval / rate
            columns[index].searches[search.row] = search
        }
        refreshMutationTime(in: index)
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
