import Testing
@testable import Dreams

struct DropDecelerationTests {
    @Test func negativeAccelerationMeetsTheSpeedFloorContinuously() throws {
        let motion = try #require(MatrixSimulation.Deceleration(enabled: true, acceleration: -10).motion(interval: 0.05))
        #expect(motion.initialSpeed == 20)
        #expect(motion.terminalSpeed == 4)
        #expect(abs(motion.brakingTime - 1.6) < 1e-12)
        #expect(abs(motion.brakingDistance - 19.2) < 1e-12)
        #expect(abs(motion.arrival(at: 10) - 0.585786437626905) < 1e-12)
        #expect(abs(motion.arrival(at: motion.brakingDistance) - motion.brakingTime) < 1e-12)
        #expect(abs(motion.arrival(at: 20) - 1.8) < 1e-12)
        #expect(abs(motion.arrival(at: 24) - motion.arrival(at: 20) - 1) < 1e-12)
        #expect(motion.arrival(at: 0) == 0)
    }

    @Test func disabledOrZeroAccelerationPreservesTheExistingRain() {
        var original = MatrixSimulation(columnCount: 6, rows: 72, glyphCount: 57)
        var disabled = MatrixSimulation(columnCount: 6, rows: 72, glyphCount: 57,
                                        deceleration: .init(enabled: false, acceleration: -120))
        var zero = MatrixSimulation(columnCount: 6, rows: 72, glyphCount: 57,
                                    deceleration: .init(enabled: true, acceleration: 0))
        for frame in 0...300 {
            let time = Double(frame) / 30
            original.advance(to: time)
            disabled.advance(to: time)
            zero.advance(to: time)
            for index in original.columns.indices {
                let expected = original.columns[index]
                for actual in [disabled.columns[index], zero.columns[index]] {
                    #expect(actual.nextWrite == expected.nextWrite)
                    #expect(actual.nextMutation == expected.nextMutation)
                    #expect(actual.generator.state == expected.generator.state)
                    #expect(actual.cells.map(\.glyph) == expected.cells.map(\.glyph))
                    #expect(actual.cells.map(\.writtenAt) == expected.cells.map(\.writtenAt))
                    #expect(actual.cells.map(\.hold) == expected.cells.map(\.hold))
                    #expect(actual.cells.map(\.fade) == expected.cells.map(\.fade))
                }
            }
        }
    }

    @Test(arguments: [-1.0, -12.0, -120.0], [0.0, 0.5, 1.0])
    func headsSlowWhileTheTailDissolvesInOrder(acceleration: Double, density: Double) throws {
        var rain = MatrixSimulation(columnCount: 1, rows: 120, glyphCount: 57, density: density,
                                    deceleration: .init(enabled: true, acceleration: acceleration))
        let duration = rain.trigger(column: 0, at: 0)
        var arrivals: [Double] = []
        var expiries: [Double] = []
        var fadeStarts: [Double] = []
        for row in 0..<rain.rows {
            rain.advance(to: rain.columns[0].nextWrite)
            let cell = rain.columns[0].cells[row]
            try #require(cell.glyph >= 0)
            arrivals.append(cell.writtenAt)
            expiries.append(cell.writtenAt + cell.hold + cell.fade)
            fadeStarts.append(cell.writtenAt + cell.hold)
        }
        let intervals = zip(arrivals.dropFirst(), arrivals).map(-)
        #expect(intervals.last! > intervals.first!)
        #expect(zip(intervals.dropFirst(), intervals).allSatisfy { $0 + 1e-10 >= $1 })
        #expect(zip(expiries.dropFirst(), expiries).allSatisfy { $0 > $1 })
        #expect(zip(fadeStarts.dropFirst(), fadeStarts).allSatisfy { $0 > $1 })
        #expect(duration > expiries.last!)
        rain.advance(to: duration)
        #expect(rain.columns[0].cells.allSatisfy { $0.glyph < 0 })
        rain.advance(to: duration + 20)
        #expect(rain.columns[0].cells.allSatisfy { $0.glyph < 0 }, "Expired glyphs must stay gone")
    }

    @Test func timeStepsDoNotChangeTheDeceleratingPath() {
        let settings = MatrixSimulation.Deceleration(enabled: true, acceleration: -12)
        var stepped = MatrixSimulation(columnCount: 3, rows: 72, glyphCount: 57, deceleration: settings)
        var jumped = stepped
        for frame in 0...300 { stepped.advance(to: Double(frame) / 30) }
        jumped.advance(to: 10)
        for index in stepped.columns.indices {
            let actual = stepped.columns[index], expected = jumped.columns[index]
            #expect(actual.headRow == expected.headRow)
            #expect(actual.nextWrite == expected.nextWrite)
            #expect(actual.generator.state == expected.generator.state)
            #expect(actual.cells.map(\.glyph) == expected.cells.map(\.glyph))
            #expect(actual.cells.map(\.writtenAt) == expected.cells.map(\.writtenAt))
        }
    }

    @Test func liveTuningOnlyChangesTheNextPacket() throws {
        var rain = MatrixSimulation(columnCount: 1, rows: 20, glyphCount: 57, density: 1)
        rain.advance(to: 0)
        let interval = rain.columns[0].interval
        rain.setDeceleration(.init(enabled: true, acceleration: -12))
        rain.advance(to: interval * 19 + 1e-10)
        #expect(rain.columns[0].motion == nil)
        #expect(abs(rain.columns[0].cells[19].writtenAt - interval * 19) < 1e-12)
        rain.advance(to: rain.columns[0].nextWrite)
        let motion = try #require(rain.columns[0].motion)
        #expect(motion.acceleration == -12)
        #expect(rain.columns[0].nextWrite - rain.columns[0].packetStartedAt > interval)
    }

    @Test func fullDensityRemainsFilledAcrossSlowPackets() {
        var rain = MatrixSimulation(columnCount: 1, rows: 40, glyphCount: 57, density: 1,
                                    deceleration: .init(enabled: true, acceleration: -120))
        rain.advance(to: 0)
        let motion = rain.columns[0].motion!
        let filledAt = motion.arrival(at: 39)
        let passTime = motion.arrival(at: 40)
        for frame in 0...600 {
            rain.advance(to: filledAt + Double(frame) * passTime / 120)
            #expect(rain.columns[0].cells.allSatisfy { $0.glyph >= 0 && !$0.isGap })
        }
    }

    @Test func malformedAccelerationCannotReverseOrStallDrops() {
        #expect(MatrixSimulation.Deceleration(enabled: true, acceleration: 100).motion(interval: 0.05) == nil)
        #expect(MatrixSimulation.Deceleration(acceleration: -.infinity).acceleration == -12)
        #expect(MatrixSimulation.Deceleration(acceleration: .nan).acceleration == -12)
        #expect(MatrixSimulation.Deceleration(acceleration: -1_000).acceleration == -120)
    }
}
