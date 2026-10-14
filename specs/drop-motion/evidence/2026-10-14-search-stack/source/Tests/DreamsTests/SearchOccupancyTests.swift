import Testing
@testable import Dreams

struct SearchOccupancyTests {
    @Test(arguments: [0.0, 0.01, 0.1, 0.5, 1.0], [1, 9])
    func fractionIsOfAllLiveGlyphsRatherThanOfColumns(fraction: Double, columnCount: Int) {
        var rain = MatrixSimulation(columnCount: columnCount, rows: 72, glyphCount: 57, density: 0.5)
        rain.setSearchFraction(fraction)
        for frame in 0...120 {
            rain.advance(to: Double(frame) / 30)
            let live = rain.columns.reduce(0) { count, column in
                count + column.cells.filter { $0.glyph >= 0 && !$0.isGap && $0.visibility > 0.002 }.count
            }
            #expect(rain.visibleSymbolCount == live)
            #expect(rain.searchingSymbolCount == rain.columns.reduce(0) { $0 + $1.searches.count })
            #expect(rain.searchingSymbolCount == Int((Double(live) * fraction).rounded(.up)))
            for column in rain.columns {
                for (row, search) in column.searches {
                    #expect(column.cells[row].glyph >= 0 && !column.cells[row].isGap)
                    #expect(column.cells[row].writtenAt == search.writtenAt)
                }
            }
        }
    }

    @Test func loweringTheQuotaStopsExcessSearchesWithoutRewritingInk() {
        var rain = MatrixSimulation(columnCount: 4, rows: 72, glyphCount: 57, density: 1)
        rain.setSearchFraction(1)
        rain.advance(to: 2)
        #expect(rain.columns.contains { $0.searches.count > 1 })
        let before = rain.columns
        rain.setSearchFraction(0)
        rain.advance(to: rain.time)
        #expect(rain.searchingSymbolCount == 0)
        for index in before.indices {
            #expect(rain.columns[index].cells.map(\.glyph) == before[index].cells.map(\.glyph))
            #expect(rain.columns[index].cells.map(\.writtenAt) == before[index].cells.map(\.writtenAt))
        }
        rain.advance(to: 2.1)
        for index in before.indices {
            for row in before[index].cells.indices where before[index].cells[row].writtenAt == rain.columns[index].cells[row].writtenAt {
                #expect(before[index].cells[row].glyph == rain.columns[index].cells[row].glyph)
            }
        }
    }

    @Test func searchesDoNotChangeMotionBrightnessOrLifetime() {
        var quiet = MatrixSimulation(columnCount: 3, rows: 72, glyphCount: 57, density: 0.5,
                                     deceleration: .init(enabled: true, acceleration: -24))
        var busy = quiet
        quiet.setSearchFraction(0)
        busy.setSearchFraction(1)
        for frame in 0...180 {
            let time = Double(frame) / 30
            quiet.advance(to: time)
            busy.advance(to: time)
            for index in quiet.columns.indices {
                #expect(quiet.columns[index].nextWrite == busy.columns[index].nextWrite)
                #expect(quiet.columns[index].generator.state == busy.columns[index].generator.state)
                for row in quiet.columns[index].cells.indices {
                    let a = quiet.columns[index].cells[row], b = busy.columns[index].cells[row]
                    #expect(a.writtenAt == b.writtenAt && a.hold == b.hold && a.fade == b.fade)
                    #expect(a.ink == b.ink && a.warmth == b.warmth && a.flashedAt == b.flashedAt)
                }
            }
        }
    }

    @Test func multipleConcurrentSearchesRemainFrameIndependent() {
        var fine = MatrixSimulation(columnCount: 4, rows: 72, glyphCount: 57)
        fine.setSearchFraction(0.35)
        var coarse = fine
        for frame in 0...600 { fine.advance(to: Double(frame) / 60) }
        coarse.advance(to: 10)
        for index in fine.columns.indices {
            let a = fine.columns[index], b = coarse.columns[index]
            #expect(a.cells.map(\.glyph) == b.cells.map(\.glyph))
            #expect(a.cells.map(\.changedAt) == b.cells.map(\.changedAt))
            #expect(a.nextWrite == b.nextWrite && a.nextMutation == b.nextMutation)
            #expect(a.searches.keys.sorted() == b.searches.keys.sorted())
            for row in a.searches.keys {
                #expect(a.searches[row]?.nextTrial == b.searches[row]?.nextTrial)
                #expect(a.searches[row]?.remaining == b.searches[row]?.remaining)
            }
        }
    }

    @Test func expiryAndHidingCancelSearchesWithoutResurrection() {
        var rain = MatrixSimulation(columnCount: 1, rows: 72, glyphCount: 57, density: 0)
        rain.setSearchFraction(1)
        let duration = rain.trigger(column: 0, at: 0)
        rain.advance(to: 1)
        #expect(rain.searchingSymbolCount > 0)
        rain.advance(to: duration)
        #expect(rain.visibleSymbolCount == 0 && rain.searchingSymbolCount == 0)
        rain.advance(to: duration + 1)
        #expect(rain.columns[0].cells.allSatisfy { $0.glyph < 0 })
        _ = rain.trigger(column: 0, at: duration + 2)
        rain.advance(to: duration + 2)
        rain.advance(to: duration + 2.1, visibility: [0])
        #expect(rain.visibleSymbolCount == 0 && rain.searchingSymbolCount == 0)
        #expect(rain.columns[0].cells.allSatisfy { $0.glyph < 0 })
    }

    @Test func invalidFractionsCannotExceedTheWholePopulation() {
        var rain = MatrixSimulation(columnCount: 1, rows: 72, glyphCount: 57)
        rain.setSearchFraction(2)
        rain.advance(to: 1)
        #expect(rain.searchingSymbolCount == rain.visibleSymbolCount)
        rain.setSearchFraction(.nan)
        rain.advance(to: rain.time)
        #expect(rain.searchingSymbolCount == rain.visibleSymbolCount)
        rain.setSearchFraction(-1)
        rain.advance(to: rain.time)
        #expect(rain.searchingSymbolCount == 0)
    }

    @Test func pendingTrialsSurviveQuotaChangesAndRetriggerWithoutStaleSearches() {
        var rain = MatrixSimulation(columnCount: 8, rows: 160, glyphCount: 57, density: 1)
        rain.advance(to: 5)
        for fraction in [1.0, 0.01, 0.0, 0.5, 1.0] {
            rain.setSearchFraction(fraction)
            rain.advance(to: rain.time)
            _ = rain.trigger(column: 0, at: rain.time)
            rain.advance(to: rain.time + 0.37)
            #expect(rain.searchingSymbolCount == rain.columns.reduce(0) { $0 + $1.searches.count })
            #expect(rain.searchingSymbolCount == Int((Double(rain.visibleSymbolCount) * fraction).rounded(.up)))
        }
        rain.advance(to: rain.time + 0.1, visibility: Array(repeating: 0, count: 8))
        #expect(rain.searchingSymbolCount == 0 && rain.visibleSymbolCount == 0)
        rain.advance(to: rain.time + 1)
        #expect(rain.searchingSymbolCount == rain.visibleSymbolCount)
        #expect(rain.columns.allSatisfy { column in
            column.searches.allSatisfy { row, search in column.cells[row].writtenAt == search.writtenAt }
        })
    }
}
