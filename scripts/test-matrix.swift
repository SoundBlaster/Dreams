import Foundation

@main
struct MatrixChecks {
    static func main() {
        var model = MatrixSimulation(columnCount: 1, rows: 90, glyphCount: 57)
        precondition(model.columns[0].cells.allSatisfy { $0.glyph == -1 })
        model.advance(to: 0)
        precondition(model.columns[0].headRow == 0)
        let first = model.columns[0].cells[0].glyph
        let step = model.columns[0].nextWrite
        model.advance(to: step - 0.000001)
        precondition(model.columns[0].headRow == 0)
        model.advance(to: step)
        precondition(model.columns[0].headRow == 1)
        precondition(model.columns[0].cells[0].glyph == first, "Typing must not scroll old glyphs")
        precondition(model.columns[0].cells[2].glyph == -1, "Nothing appears below the cursor")

        let mutation = model.columns[0].nextMutation
        model.advance(to: mutation - 0.000001)
        let before = model.columns[0].cells.map(\.glyph)
        model.advance(to: mutation)
        let changed = zip(before, model.columns[0].cells.map(\.glyph)).filter { $0 != $1 }.count
        precondition(changed == 1, "One mutation event replaces exactly one existing glyph")
        let mutationDelay = model.columns[0].nextMutation - mutation
        precondition(model.columns[0].search == nil
            ? (0.12...0.62).contains(mutationDelay)
            : (0.035...0.065).contains(mutationDelay),
            "Single replacements and search bursts need distinct cadences")

        var searchModel = MatrixSimulation(columnCount: 1, rows: 300, glyphCount: 57)
        for _ in 0..<300 {
            searchModel.advance(to: min(searchModel.columns[0].nextWrite, searchModel.columns[0].nextMutation))
            if searchModel.columns[0].search != nil { break }
        }
        guard let search = searchModel.columns[0].search else { preconditionFailure("Expected a search burst") }
        let searchedInk = searchModel.columns[0].cells[search.row]
        precondition((3...7).contains(search.remaining))
        for remaining in stride(from: search.remaining, through: 1, by: -1) {
            let event = searchModel.columns[0].nextMutation
            let before = searchModel.columns[0].cells
            searchModel.advance(to: event)
            let after = searchModel.columns[0].cells
            precondition(before[search.row].glyph != after[search.row].glyph,
                "Each trial must visibly change the same glyph")
            precondition(before.indices.allSatisfy { row in
                row == search.row || before[row].writtenAt != after[row].writtenAt
                    || before[row].glyph == after[row].glyph
            }, "A burst must stay on one position, not hop between letters")
            precondition(after[search.row].writtenAt == searchedInk.writtenAt
                && after[search.row].ink == searchedInk.ink,
                "Search trials must not extend lifetime or randomize brightness")
            precondition(after[search.row].flashedAt == searchedInk.flashedAt,
                "Search trials and their final glyph must not trigger a white glint")
            if remaining > 1 {
                precondition(searchModel.columns[0].search?.remaining == remaining - 1)
            }
        }
        precondition(searchModel.columns[0].search == nil)
        precondition(searchModel.columns[0].cells[search.row].glyph == search.targetGlyph,
            "The burst must settle on its selected final glyph")
        searchModel.advance(to: searchModel.time + 0.1)
        precondition(searchModel.columns[0].cells[search.row].glyph == search.targetGlyph,
            "The final glyph must remain stable after the burst")
        searchModel.advance(to: searchModel.time + 0.1, visibility: [0])
        precondition(searchModel.columns[0].search == nil
            && searchModel.columns[0].cells.allSatisfy { $0.glyph == -1 },
            "Hiding a column must cancel its searches")

        var coarse = MatrixSimulation(columnCount: 12, rows: 90, glyphCount: 57)
        var fine = MatrixSimulation(columnCount: 12, rows: 90, glyphCount: 57)
        coarse.advance(to: 35)
        precondition(coarse.columns.contains { $0.cells.contains { $0.isGap && $0.glyph >= 0 } },
            "Cursors must leave deliberate empty cells inside printed columns")
        for frame in 0...2100 { fine.advance(to: Double(frame) / 60) }
        for c in coarse.columns.indices {
            precondition(coarse.columns[c].cells.map(\.glyph) == fine.columns[c].cells.map(\.glyph))
            precondition(coarse.columns[c].nextWrite == fine.columns[c].nextWrite)
        }
        let stable = fine.columns[0].cells.map(\.glyph)
        fine.advance(to: 35)
        precondition(stable == fine.columns[0].cells.map(\.glyph), "Rendering twice cannot mutate the grid")

        var lifecycle = MatrixSimulation(columnCount: 2, rows: 10_000, glyphCount: 57)
        lifecycle.advance(to: 1)
        lifecycle.advance(to: 1.1, visibility: [0.2, 1])
        let fadedInk = lifecycle.columns[0].cells[0]
        lifecycle.advance(to: 1.2, visibility: [1, 1])
        precondition(lifecycle.columns[0].cells[0].visibility == fadedInk.visibility,
            "Rising activity must not brighten old fading ink")
        lifecycle.advance(to: 2, visibility: [0, 1])
        lifecycle.advance(to: 30, visibility: [0, 1])
        precondition(lifecycle.columns[0].cells.allSatisfy { $0.glyph == -1 },
            "Hidden columns must stay empty while other columns continue")
        precondition(lifecycle.columns[1].cells.contains { $0.glyph >= 0 })
        lifecycle.advance(to: 30, visibility: [1, 1])
        precondition(lifecycle.columns[0].cells.allSatisfy { $0.glyph == -1 },
            "Reactivation must not reveal prefilled cells")
        let restart = lifecycle.columns[0].nextWrite
        lifecycle.advance(to: restart, visibility: [1, 1])
        precondition(lifecycle.columns[0].headRow == 0)
        precondition(lifecycle.columns[0].cells.dropFirst().allSatisfy { $0.glyph == -1 },
            "The new pass must start with a single top cell")
        let expiry = restart + lifecycle.columns[0].hold + lifecycle.columns[0].fade + 0.001
        lifecycle.advance(to: expiry)
        precondition(lifecycle.columns[0].cells[0].glyph == -1, "Expired ink must be erased")
        lifecycle.advance(to: expiry + 1)
        precondition(lifecycle.columns[0].cells[0].glyph == -1,
            "Mutation must not resurrect an expired cell")
        // Exercise several complete packets at actual screen height, including
        // a fully dark interval and a fresh single-cell restart after each one.
        var rain = MatrixSimulation(columnCount: 1, rows: 72, glyphCount: 57, density: 0)
        for _ in 0..<5 {
            let start = rain.columns[0].nextWrite
            let interval = rain.columns[0].interval
            rain.advance(to: start + 60 * interval)
            precondition(rain.columns[0].cells.prefix(20).allSatisfy { $0.glyph == -1 },
                "The rear must clear the upper screen before the head reaches the bottom")
            precondition(rain.columns[0].cells.contains { $0.glyph >= 0 && !$0.isGap },
                "A descending packet must still have visible ink")
            rain.advance(to: start + 71 * interval + 0.000001)
            let bottom = rain.columns[0].lastWrite
            let lifetime = rain.columns[0].hold + rain.columns[0].fade
            let next = rain.columns[0].nextWrite
            precondition(next > bottom + lifetime + 0.24, "Packets need a genuinely dark gap")
            rain.advance(to: bottom + lifetime + 0.001)
            precondition(rain.columns[0].cells.allSatisfy { $0.glyph == -1 },
                "The entire packet must drain offscreen")
            rain.advance(to: next - 0.000001)
            precondition(rain.columns[0].cells.allSatisfy { $0.glyph == -1 },
                "No old ink may return during the gap")
            rain.advance(to: next)
            precondition(rain.columns[0].headRow == 0
                && rain.columns[0].cells.dropFirst().allSatisfy { $0.glyph == -1 },
                "The next packet must type from the top, not reveal a whole column")
            // nextWrite is now row 1; the next iteration needs row 0's timestamp.
            rain.advance(to: next + 71 * interval + lifetime + 0.001)
        }
        var sparse = MatrixSimulation(columnCount: 8, rows: 72, glyphCount: 57, density: 0)
        var dense = MatrixSimulation(columnCount: 8, rows: 72, glyphCount: 57, density: 1)
        var sparseInk = 0
        var denseInk = 0
        for frame in 0...1800 {
            let time = Double(frame) / 30
            sparse.advance(to: time)
            dense.advance(to: time)
            if frame > 150 {
                sparseInk += sparse.columns.flatMap(\.cells).filter { $0.glyph >= 0 && !$0.isGap }.count
                denseInk += dense.columns.flatMap(\.cells).filter { $0.glyph >= 0 && !$0.isGap }.count
            }
        }
        precondition(denseInk > sparseInk * 2, "Density must materially increase sustained screen occupancy")
        precondition(dense.columns.allSatisfy { column in
            column.cells.allSatisfy { $0.glyph >= 0 && !$0.isGap }
        }, "100 percent must fill every grid cell after warmup, without random gaps")
        var overlapCoarse = MatrixSimulation(columnCount: 4, rows: 72, glyphCount: 57, density: 1)
        var overlapFine = overlapCoarse
        overlapCoarse.advance(to: 30)
        for frame in 0...1800 { overlapFine.advance(to: Double(frame) / 60) }
        precondition(overlapCoarse.columns.map { $0.cells.map(\.glyph) }
            == overlapFine.columns.map { $0.cells.map(\.glyph) },
            "Continuous full-density passes must remain independent of frame rate")
        var tuning = MatrixSimulation(columnCount: 1, rows: 72, glyphCount: 57, density: 0)
        tuning.advance(to: 0)
        let tail = tuning.columns[0].hold + tuning.columns[0].fade * 0.5
        tuning.advance(to: tail)
        let opacity = tuning.opacity(column: 0, row: 0)
        tuning.setDensity(1)
        tuning.advance(to: tail + 0.001)
        precondition(tuning.opacity(column: 0, row: 0) <= opacity,
            "Increasing density must not brighten an existing tail")
        var sequential = MatrixSimulation(columnCount: 1, rows: 72, glyphCount: 57, fadeRows: 1)
        sequential.advance(to: 0)
        let hold = sequential.columns[0].hold
        let tick = sequential.columns[0].interval
        sequential.advance(to: hold + tick * 0.5)
        precondition(abs(sequential.opacity(column: 0, row: 0) - 0.5) < 0.001)
        precondition(sequential.opacity(column: 0, row: 1) == 1,
            "The next glyph must stay intact while its predecessor dissolves")
        sequential.advance(to: hold + tick * 1.5)
        precondition(sequential.opacity(column: 0, row: 0) == 0)
        precondition(abs(sequential.opacity(column: 0, row: 1) - 0.5) < 0.001,
            "Dissolution must advance exactly one row after the preceding glyph disappears")
        var soft = MatrixSimulation(columnCount: 1, rows: 72, glyphCount: 57, fadeRows: 8)
        soft.advance(to: 0)
        soft.advance(to: soft.columns[0].hold + soft.columns[0].interval * 4)
        precondition((0..<4).allSatisfy {
            let opacity = soft.opacity(column: 0, row: $0)
            return opacity > 0 && opacity < 1
        }, "A wider dissolve must fade several glyphs concurrently")
        let beforeTuning = soft.opacity(column: 0, row: 0)
        soft.setFadeRows(1)
        soft.advance(to: soft.time + 0.001)
        precondition(soft.opacity(column: 0, row: 0) <= beforeTuning)
        let dim = MatrixSimulation.Symbol(ink: 0.14)
        let bright = MatrixSimulation.Symbol(ink: 0.84)
        precondition(dim.ink(brightnessSpread: 0) == bright.ink(brightnessSpread: 0),
            "Zero spread must equalize ordinary glyph brightness")
        precondition(abs(dim.ink(brightnessSpread: 1) - dim.ink) < 0.00001
            && abs(bright.ink(brightnessSpread: 1) - bright.ink) < 0.00001,
            "Full spread must preserve the original stable random ink")
        let fullDifference = bright.ink(brightnessSpread: 1) - dim.ink(brightnessSpread: 1)
        let halfDifference = bright.ink(brightnessSpread: 0.5) - dim.ink(brightnessSpread: 0.5)
        precondition(abs(halfDifference * 2 - fullDifference) < 0.00001,
            "Intermediate spread must reduce differences proportionally")
        func mutations(rate: Double) -> Int {
            var sim = MatrixSimulation(columnCount: 12, rows: 72, glyphCount: 57)
            var changes = 0
            for tick in 1...1200 {
                let previous = sim.columns
                sim.advance(to: Double(tick) / 100, mutationRate: rate)
                for column in sim.columns.indices {
                    for row in 0..<72 {
                        let old = previous[column].cells[row]
                        let new = sim.columns[column].cells[row]
                        if old.glyph >= 0 && old.writtenAt == new.writtenAt && old.glyph != new.glyph {
                            changes += 1
                        }
                    }
                }
            }
            return changes
        }
        precondition(mutations(rate: 3) > mutations(rate: 1) * 2,
            "High activity must increase glyph searches without moving the cells")
        var pulse = MatrixSimulation(columnCount: 1, rows: 72, glyphCount: 57)
        let pulseDuration = pulse.trigger(column: 0, at: 0)
        pulse.advance(to: pulseDuration + 1)
        let lastPulseWrite = pulse.columns[0].lastWrite
        precondition(pulse.columns[0].headRow == 71 && pulse.columns[0].cells.allSatisfy { $0.glyph < 0 },
            "An event packet must finish and drain completely")
        pulse.advance(to: pulseDuration + 10)
        precondition(pulse.columns[0].lastWrite == lastPulseWrite,
            "An event packet must not start another pass on its own")
        pulse.finishPulse(column: 0)
        pulse.advance(to: pulseDuration + 11)
        pulse.advance(to: pulseDuration + 11.5)
        precondition(pulse.columns[0].lastWrite > lastPulseWrite,
            "Ordinary rain must resume after an event packet")
        print("PASS: typing, mutation, frame-rate independence, irreversible fade, hidden-column restart, expired-cell removal, draining packets, density occupancy, sequential/wide dissolve, brightness spread and live tuning")
    }
}
