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
}
