import Foundation

@main
struct ActivityChecks {
    static func main() {
        let full = RainActivity.attack + RainActivity.hold
        var rain = RainActivity()
        let calm = RainActivity.idleLevel
        precondition(abs(rain.level(at: 100) - calm) < 0.00001, "No messages means a faint calm rain")

        rain.surge(at: 100)
        precondition(abs(rain.level(at: 100) - calm) < 0.00001, "A surge must not pop into view")
        precondition(rain.level(at: 100 + RainActivity.attack / 2) > calm
            && rain.level(at: 100 + RainActivity.attack / 2) < 1, "A surge rises smoothly")
        precondition(rain.level(at: 100 + RainActivity.attack) == 1
            && rain.level(at: 100 + full - 0.01) == 1, "A message floods the screen and holds")
        precondition(rain.coverage(at: 100 + 1, density: 0.58) == 1,
            "At full flood every column rains")

        let falling = rain.level(at: 100 + full + RainActivity.decay)
        precondition(falling < 1 && falling > calm, "Then it falls back towards calm")
        precondition(rain.level(at: 100 + full + 3 * RainActivity.decay) - calm < 0.05 * (1 - calm),
            "Three decay constants later the rain is calm again")
        precondition(abs(rain.coverage(at: 200, density: 0) - Double(calm)) < 0.00001,
            "At density 0 the calm coverage is the calm level")
        precondition(rain.coverage(at: 200, density: 1) == 1, "Density 100% fills every column, calm or not")
        precondition(rain.coverage(at: 200, density: 0.5) > Double(calm)
            && rain.coverage(at: 200, density: 0.5) < 1, "Density raises calm coverage gradually")

        // A message during the fall floods again from the current level, without a jump.
        let t = 100 + full + RainActivity.decay
        let before = rain.level(at: t)
        rain.surge(at: t)
        precondition(abs(rain.level(at: t) - before) < 0.00001, "Re-flooding starts where the rain is")
        precondition(rain.level(at: t + RainActivity.attack) == 1)

        // A busy agent (a message every 2 s) keeps the rain dense throughout.
        var busy = RainActivity()
        var lowest: Float = 1
        for step in 0..<40 {
            let time = Double(step) * 0.25
            if step % 8 == 0 { busy.surge(at: time) }
            if time > 1 { lowest = min(lowest, busy.level(at: time)) }
        }
        precondition(lowest > 0.85, "Frequent messages keep the rain dense (lowest \(lowest))")

        // The idle slider sets the calm level, live.
        var tuned = RainActivity()
        tuned.update(at: 0, idleIntensity: 1)
        precondition(tuned.level(at: 1) > 0.4, "Idle slider raises the calm background")
        tuned.update(at: 1, idleIntensity: 0)
        precondition(tuned.level(at: 2) == 0, "Idle 0% leaves the screen black between messages")
        tuned.surge(at: 2)
        precondition(tuned.level(at: 3) == 1, "Disabling idle must not disable surges")
        print("PASS: calm rain, smooth flood on a message, hold, fall to calm, re-flood mid-fall, busy agent stays dense, idle slider")
    }
}
