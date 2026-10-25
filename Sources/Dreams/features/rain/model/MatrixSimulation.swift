import Foundation

/// A fixed character grid. Only a column's writing cursor advances; cells never move.
struct MatrixSimulation {
    private static let tailIntervalScale = 1.6

    /// Stable timestamp/index ordering, shared by the grid and each column's trials.
    struct Schedule {
        struct Entry {
            let time: Double
            let index: Int
            func precedes(_ other: Entry) -> Bool {
                time == other.time ? index < other.index : time < other.time
            }
        }
        private var heap: [Entry] = []
        var first: Entry? { heap.first }

        mutating func insert(time: Double, index: Int) {
            guard time.isFinite else { return }
            heap.append(Entry(time: time, index: index))
            var child = heap.count - 1
            while child > 0 {
                let parent = (child - 1) / 2
                guard heap[child].precedes(heap[parent]) else { break }
                heap.swapAt(child, parent)
                child = parent
            }
        }

        @discardableResult mutating func pop() -> Entry? {
            guard let result = heap.first else { return nil }
            let last = heap.removeLast()
            guard !heap.isEmpty else { return result }
            heap[0] = last
            var parent = 0
            while parent * 2 + 1 < heap.count {
                let left = parent * 2 + 1, right = left + 1
                let child = right < heap.count && heap[right].precedes(heap[left]) ? right : left
                guard heap[child].precedes(heap[parent]) else { break }
                heap.swapAt(child, parent)
                parent = child
            }
            return result
        }

        mutating func removeAll() { heap.removeAll(keepingCapacity: true) }
    }

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
        var searchSchedule = Schedule()
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
    private var events = Schedule()
    private var scheduledTimes: [Double] = []
    private(set) var searchingSymbolCount = 0
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

    /// Creates an empty grid whose schedules begin at the supplied simulation time.
    init(columnCount: Int, rows: Int, glyphCount: Int, seed: UInt64 = 0xD2EA_5EED,
         density: Double = 0.8, fadeRows: Double = 1, deceleration: Deceleration = Deceleration(),
         startTime: Double = 0) {
        self.rows = rows
        time = startTime.isFinite ? max(0, startTime) : 0
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
                nextWrite: time + delay, nextMutation: time + delay + 0.15 + unit() * 0.35,
                interval: interval, hold: lifetime - fade,
                fade: fade, generator: Generator(state: seed &+ UInt64(index) &* 7919)))
        }
        for index in columns.indices { columns[index].nextMutation = .infinity }
        scheduledTimes = Array(repeating: .infinity, count: columns.count)
        for index in columns.indices { scheduleColumn(index) }
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
            searchingSymbolCount -= 1
            addAvailable(Position(column: index, row: row))
        }
        columns[index].nextMutation = .infinity
        columns[index].searchSchedule.removeAll()
        scheduleColumn(index)
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
                columns[index].searchSchedule.removeAll()
                scheduleColumn(index)
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
            scheduleColumn(index)
        }
        maintainSearchShare(at: time, rate: rate)
        // One global timestamp order keeps pool selection independent of frame subdivision.
        while let pending = events.first, pending.time <= target {
            events.pop()
            let index = pending.index
            guard scheduledTimes[index] == pending.time else { continue }
            scheduledTimes[index] = .infinity
            let eventTime = pending.time
            var occupancyChanged = true
            if columns[index].nextWrite <= columns[index].nextMutation
                && columns[index].nextWrite <= columns[index].nextExpiry {
                writeNext(in: index, visibility: min(1, max(0, visibility?[index] ?? 1)), coverage: coverage)
            } else if columns[index].nextExpiry <= columns[index].nextMutation {
                expireCells(in: index, at: eventTime)
            } else {
                occupancyChanged = advanceSearch(in: index, at: eventTime, rate: rate)
            }
            if occupancyChanged { maintainSearchShare(at: eventTime, rate: rate) }
        }
        time = target
    }

    private func nextEvent(in index: Int) -> Double {
        min(columns[index].nextWrite, columns[index].nextMutation, columns[index].nextExpiry)
    }

    private mutating func scheduleColumn(_ index: Int) {
        let next = nextEvent(in: index)
        guard scheduledTimes[index] != next else { return }
        scheduledTimes[index] = next
        events.insert(time: next, index: index)
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
        scheduleColumn(index)
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
        scheduleColumn(index)
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
        // Overwritten/cancelled trials are lazily discarded without scanning every search.
        while let pending = columns[index].searchSchedule.first,
              columns[index].searches[pending.index]?.nextTrial != pending.time {
            columns[index].searchSchedule.pop()
        }
        columns[index].nextMutation = columns[index].searchSchedule.first?.time ?? .infinity
        scheduleColumn(index)
    }

    private mutating func removePosition(_ position: Position) {
        removeAvailable(position)
        if columns[position.column].searches.removeValue(forKey: position.row) != nil {
            searchingSymbolCount -= 1
        }
        refreshMutationTime(in: position.column)
    }

    private mutating func maintainSearchShare(at time: Double, rate: Double) {
        let target = Int(ceil(Double(visibleSymbolCount) * searchFraction))
        var active = searchingSymbolCount
        if active > target {
            for index in columns.indices {
                for row in columns[index].searches.keys.sorted() where active > target {
                    columns[index].searches.removeValue(forKey: row)
                    searchingSymbolCount -= 1
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
            columns[position.column].searchSchedule.insert(time: time + interval / rate, index: position.row)
            refreshMutationTime(in: position.column)
            searchingSymbolCount += 1
            active += 1
        }
    }

    /// Only completion/cancellation changes occupancy; intermediate trials need no quota pass.
    private mutating func advanceSearch(in index: Int, at time: Double, rate: Double) -> Bool {
        guard let pending = columns[index].searchSchedule.pop(),
              var search = columns[index].searches[pending.index] else {
            refreshMutationTime(in: index)
            return false
        }
        let cell = columns[index].cells[search.row]
        guard cell.glyph >= 0, !cell.isGap, cell.writtenAt == search.writtenAt,
              time < cell.writtenAt + cell.hold + cell.fade else {
            columns[index].searches.removeValue(forKey: search.row)
            searchingSymbolCount -= 1
            refreshMutationTime(in: index)
            return true
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
            searchingSymbolCount -= 1
            addAvailable(Position(column: index, row: search.row))
        } else {
            search.nextTrial = time + search.interval / rate
            columns[index].searches[search.row] = search
            columns[index].searchSchedule.insert(time: search.nextTrial, index: search.row)
        }
        refreshMutationTime(in: index)
        return final
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
        guard c.headRow == row, c.cells[row].glyph >= 0 else { return 0 }
        // The drop owns its current row until the next row arrival, even when
        // braking makes that step longer than the former fixed 0.11s flash.
        // Use the flight step, not nextWrite: a packet pause or one-shot end
        // must not leave the bottom glyph permanently white.
        let step = c.motion.map {
            $0.arrival(at: Double(row + 1)) - $0.arrival(at: Double(row))
        } ?? c.interval
        return Float(max(0, min(1, 1 - (time - c.lastWrite - step) / 0.11)))
    }

    /// Fast head-only trials are a presentation: they never rewrite stationary ink
    /// or consume the quota/random generator used by searches in the trail.
    func headGlyph(column: Int, row: Int) -> Int {
        let c = columns[column]
        let stored = c.cells[row].glyph
        guard glyphCount > 1, headIntensity(column: column, row: row) > 0 else { return stored }
        let step = c.motion.map {
            $0.arrival(at: Double(row + 1)) - $0.arrival(at: Double(row))
        } ?? c.interval
        // Clamp at the final arrival: a bottom head fades without continuing trials.
        let tick = Int(max(0, min(step, time - c.lastWrite)) / 0.035)
        var seed = c.lastWrite.bitPattern ^ UInt64(truncatingIfNeeded: column) &* 0x9E3779B97F4A7C15
        seed = (seed ^ (seed >> 30)) &* 0xBF58476D1CE4E5B9
        seed = (seed ^ (seed >> 27)) &* 0x94D049BB133111EB
        seed ^= seed >> 31
        let base = Int(seed % UInt64(glyphCount))
        var stride = 1 + Int((seed >> 32) % UInt64(glyphCount - 1))
        // A coprime stride visits the whole repertoire without identical neighbours.
        while greatestCommonDivisor(stride, glyphCount) != 1 { stride = stride % (glyphCount - 1) + 1 }
        return (base + (tick % glyphCount) * stride) % glyphCount
    }

    private func greatestCommonDivisor(_ left: Int, _ right: Int) -> Int {
        var a = left, b = right
        while b != 0 { (a, b) = (b, a % b) }
        return a
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
