import Testing
@testable import Dreams

struct DropHeadTests {
    @Test func brakingDoesNotLeaveTheCurrentHeadDarkBetweenWrites() {
        var rain = MatrixSimulation(columnCount: 1, rows: 72, glyphCount: 57, density: 1,
                                    deceleration: .init(enabled: true, acceleration: -120))
        rain.setSearchFraction(0)
        rain.advance(to: 0)
        for _ in 0..<50 {
            rain.advance(to: rain.columns[0].nextWrite)
            let column = rain.columns[0]
            let step = column.nextWrite - column.lastWrite
            rain.advance(to: column.lastWrite + step * 0.9)
            #expect(rain.headIntensity(column: 0, row: column.headRow) > 0.8)
            if column.headRow > 0 {
                #expect(rain.headIntensity(column: 0, row: column.headRow - 1) == 0)
            }
        }
    }

    @Test func aFinishedPacketDoesNotKeepItsLastHeadLitDuringThePause() {
        var rain = MatrixSimulation(columnCount: 1, rows: 8, glyphCount: 57, density: 0)
        rain.setSearchFraction(0)
        _ = rain.trigger(column: 0, at: 0)
        rain.advance(to: 1)
        #expect(rain.columns[0].nextWrite == .infinity)
        #expect(rain.headIntensity(column: 0, row: 7) == 0)
    }
    @Test func theSameHeadCyclesWithZeroTrailSearch() {
        var rain = MatrixSimulation(columnCount: 1, rows: 72, glyphCount: 57, density: 1,
                                    deceleration: .init(enabled: true, acceleration: -120))
        rain.setSearchFraction(0)
        rain.advance(to: 0)
        for _ in 0..<20 { rain.advance(to: rain.columns[0].nextWrite) }
        let column = rain.columns[0]
        let row = column.headRow
        let original = column.cells[row]
        var glyphs = Set<Int>()
        for offset in [0.005, 0.04, 0.075] {
            rain.advance(to: column.lastWrite + offset)
            #expect(rain.columns[0].headRow == row)
            #expect(rain.headIntensity(column: 0, row: row) == 1)
            glyphs.insert(rain.headGlyph(column: 0, row: row))
            #expect(rain.searchingSymbolCount == 0)
            #expect(rain.columns[0].cells[row].glyph == original.glyph)
            #expect(rain.columns[0].cells[row].changedAt == original.changedAt)
            #expect(rain.columns[0].cells[row].writtenAt == original.writtenAt)
            #expect(rain.columns[0].cells[row].ink == original.ink)
            #expect(rain.columns[0].cells[row].flashedAt == original.flashedAt)
            #expect(rain.headGlyph(column: 0, row: row - 1) == column.cells[row - 1].glyph)
        }
        #expect(glyphs.count == 3)
    }

    @Test func headTrialsAreDeterministicAndIndependentOfTheSearchQuota() {
        var sparse = MatrixSimulation(columnCount: 2, rows: 72, glyphCount: 57, density: 1)
        var saturated = sparse
        sparse.setSearchFraction(0)
        saturated.setSearchFraction(1)
        sparse.advance(to: 0)
        for frame in 0...120 {
            let time = Double(frame) / 60
            sparse.advance(to: time)
            saturated.advance(to: time)
            for column in sparse.columns.indices {
                let row = sparse.columns[column].headRow
                guard row >= 0 else { continue }
                #expect(row == saturated.columns[column].headRow)
                let glyph = sparse.headGlyph(column: column, row: row)
                #expect(glyph == sparse.headGlyph(column: column, row: row))
                #expect(glyph == saturated.headGlyph(column: column, row: row))
            }
        }
    }

    @Test func aSingleGlyphRepertoireAndExpiredHeadDoNotStartTrials() {
        var rain = MatrixSimulation(columnCount: 1, rows: 8, glyphCount: 1, density: 0)
        rain.setSearchFraction(0)
        _ = rain.trigger(column: 0, at: 0)
        rain.advance(to: 0.02)
        #expect(rain.headGlyph(column: 0, row: 0) == 0)
        rain.advance(to: 20)
        #expect(rain.headGlyph(column: 0, row: 7) == -1)
        #expect(rain.headIntensity(column: 0, row: 7) == 0)
    }

    @Test func theBottomHeadStopsCyclingAfterItsFlightStep() {
        var rain = MatrixSimulation(columnCount: 1, rows: 8, glyphCount: 57, density: 0)
        rain.setSearchFraction(0)
        _ = rain.trigger(column: 0, at: 0)
        for _ in 0..<8 { rain.advance(to: rain.columns[0].nextWrite) }
        let column = rain.columns[0]
        #expect(column.nextWrite == .infinity)
        rain.advance(to: column.lastWrite + column.interval + 0.01)
        let last = rain.headGlyph(column: 0, row: 7)
        rain.advance(to: column.lastWrite + column.interval + 0.06)
        #expect(rain.headGlyph(column: 0, row: 7) == last)
    }

}
