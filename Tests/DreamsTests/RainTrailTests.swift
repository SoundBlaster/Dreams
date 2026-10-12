import Testing
@testable import Dreams

struct RainTrailTests {
    @Test(arguments: [0.0, 0.25, 0.5])
    func headOutrunsRearAndStretchesTrace(density: Double) throws {
        var rain = MatrixSimulation(columnCount: 1, rows: 120, glyphCount: 57, density: density)
        _ = rain.trigger(column: 0, at: 0)
        rain.advance(to: 0)
        let step = rain.columns[0].interval
        let firstCell = rain.columns[0].cells[0]
        let firstHead = Int(((firstCell.hold + firstCell.fade) / step).rounded(.up)) + 8

        rain.advance(to: (Double(firstHead) + 0.001) * step)
        let firstRear = try #require(visibleRear(in: rain))
        let previousHead = rain.columns[0].headRow
        rain.advance(to: (Double(firstHead + 24) + 0.001) * step)
        let secondRear = try #require(visibleRear(in: rain))
        let headTravel = rain.columns[0].headRow - previousHead
        let rearTravel = secondRear - firstRear

        #expect(headTravel == 24)
        #expect(rearTravel > 0)
        #expect(headTravel > rearTravel, "The trace must lengthen while both ends descend")
    }

    @Test(arguments: [1, 3, 16])
    func fadeWidthCountsRowsAtTheSlowerRear(width: Int) {
        var rain = MatrixSimulation(columnCount: 1, rows: 120, glyphCount: 57,
                                    density: 0.5, fadeRows: Double(width))
        _ = rain.trigger(column: 0, at: 0)
        rain.advance(to: 0)
        let start = rain.columns[0].hold
        let tailStep = rain.columns[0].tailInterval
        rain.advance(to: start + (Double(width) - 0.5) * tailStep)
        let dissolving = (0..<120).filter {
            let opacity = rain.opacity(column: 0, row: $0)
            return opacity > 0 && opacity < 1
        }
        #expect(dissolving == Array(0..<width))
        #expect(rain.opacity(column: 0, row: width) == 1)
        rain.advance(to: start + (Double(width) + 0.5) * tailStep)
        #expect(rain.opacity(column: 0, row: 0) == 0)
        #expect(rain.opacity(column: 0, row: width) > 0)
    }

    @Test(arguments: [0.0, 0.5, 1.0])
    func eventDurationIncludesTheWholeStretchedTrace(density: Double) {
        var rain = MatrixSimulation(columnCount: 1, rows: 120, glyphCount: 57, density: 0)
        // Live tuning must be included even if the preceding packet used another density.
        rain.setDensity(density)
        let duration = rain.trigger(column: 0, at: 0)
        rain.advance(to: Double(rain.rows - 1) * rain.columns[0].interval + 0.000001)
        let last = rain.columns[0].cells[rain.rows - 1]
        let expires = last.writtenAt + last.hold + last.fade
        #expect(duration > expires)
        rain.advance(to: expires - last.fade * 0.5)
        #expect(rain.opacity(column: 0, row: rain.rows - 1) > 0)
        rain.advance(to: duration)
        #expect(rain.columns[0].cells.allSatisfy { $0.glyph < 0 })
        let lastWrite = rain.columns[0].lastWrite
        rain.advance(to: duration + 10)
        #expect(rain.columns[0].lastWrite == lastWrite)
        #expect(visibleRear(in: rain) == nil)
    }

    private func visibleRear(in rain: MatrixSimulation) -> Int? {
        rain.columns[0].cells.indices.first {
            let cell = rain.columns[0].cells[$0]
            return cell.glyph >= 0 && !cell.isGap && rain.opacity(column: 0, row: $0) > 0.01
        }
    }
}
