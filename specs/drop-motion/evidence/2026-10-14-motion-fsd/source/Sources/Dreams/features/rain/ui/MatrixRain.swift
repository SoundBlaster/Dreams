// Sources/Dreams/features/rain/ui/MatrixRain.swift:113-128
        _ = glyph("?", keyword: true)
        for symbol in symbols { _ = glyph(String(symbol), keyword: false) }
    }

    func draw(encoder: any MTLRenderCommandEncoder, resolution: SIMD2<Float>, brightness: Float,
              previewTime: Float? = nil, demoWorkingAgents: Int? = nil, columnCount: Int = 0, density: Double = 0.8,
              fadeRows: Double = 1, speed: Double = 1, brightnessSpread: Double = 1, glow: Double = 1, idleIntensity: Double = 0.2,
              deceleration: MatrixSimulation.Deceleration = .init(),
              keywordTint: SIMD3<Float> = SIMD3(0.10, 0.65, 0.24), keywordBrightness: Double = 1,
              rainTint: SIMD3<Float> = SIMD3(0.008, 0.26, 0.055)) {
        let now = ProcessInfo.processInfo.systemUptime
        if now >= nextRefresh {
            if let snapshot = try? feed.snapshot() { messages = snapshot }
            // Quantized targets avoid continuously restarting the smooth activity transition.
            actionPressure = (KeywordMessage.pressure(messages) * 10).rounded() / 10
            let recent = messages.flatMap { $0.events ?? [] }
// Sources/Dreams/features/rain/ui/MatrixRain.swift:175-190
        if simulation?.columns.count != columns || simulation?.rows != rows {
            pulseWords.removeAll()
            selections.removeAll()
            simulation = MatrixSimulation(columnCount: columns, rows: rows, glyphCount: symbols.count, density: density, fadeRows: fadeRows)
        }
        simulation!.setDensity(density)
        simulation!.setFadeRows(fadeRows)
        simulation!.setDeceleration(deceleration)
        for column in Array(pulseWords.keys) where pulseWords[column]!.ends <= simulationClock {
            simulation!.finishPulse(column: column)
            pulseWords.removeValue(forKey: column)
        }
        for event in pendingEvents {
            let column = (columns / 5 + eventColumn * 37) % columns
            eventColumn += 1
            let duration = simulation!.trigger(column: column, at: simulationClock)
