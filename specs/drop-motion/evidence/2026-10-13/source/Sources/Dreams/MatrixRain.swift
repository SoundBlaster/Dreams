// Sources/Dreams/MatrixRain.swift: 117-198
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
                .filter { Date().timeIntervalSince($0.time) < 8 }
                .sorted { $0.time < $1.time }
            pendingEvents += recent.filter { !seenEvents.contains($0.id) }.suffix(6)
            seenEvents.formUnion(recent.map(\.id))
            if seenEvents.count > 1024 { seenEvents = Set(recent.map(\.id)) }
            // Any new message from an agent (prompt, tool call, result, stop) floods the rain.
            if let newest = messages.map(\.updatedAt).max(), newest > lastMessageUpdate {
                lastMessageUpdate = newest
                surgePending = true
            }
            nextRefresh = now + 1
        }
        let active = messages.filter { $0.expiresAt > Date() && $0.isWorking }
        let t = previewTime ?? Float(now - began)
        let time = Double(t)
        if time < (lastFrameTime ?? 0) {
            activity = RainActivity(idleIntensity: idleIntensity)
            lastFrameTime = nil
            simulationClock = 0
            pulseWords.removeAll()
            simulation = nil
        }
        if lastFrameTime == nil { activity = RainActivity(idleIntensity: idleIntensity) }
        activity.update(at: time, idleIntensity: idleIntensity)
        // Offline renders (--render-demo) keep flooding while their scripted agents work.
        if surgePending || (demoWorkingAgents ?? 0) > 0 {
            activity.surge(at: time)
            surgePending = false
        }
        let elapsed = max(0, time - (lastFrameTime ?? 0))
        mutationPressure += (actionPressure - mutationPressure)
            * (1 - exp(-elapsed / (actionPressure > mutationPressure ? 0.8 : 3)))
        lastFrameTime = time
        guard activity.level(at: time) > 0.001 || !pendingEvents.isEmpty
            || pulseWords.values.contains(where: { $0.ends > simulationClock }) else {
            simulation = nil
            simulationClock = 0
            selections.removeAll()
            return
        }
        // Activity transitions and texture noise stay on real time. Only the
        // rain's writing, mutation and dissolution clock follows this control.
        simulationClock += elapsed * min(3, max(0.25, speed))
        let aspect = max(0.1, resolution.x / max(1, resolution.y))
        let columns = columnCount == 0 ? max(24, Int(aspect * 72)) : min(240, max(24, columnCount))
        let rows = columnCount == 0 ? 72 : max(8, Int((Float(columns) / aspect).rounded()))
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
            // Call lines are printed verbatim: case and spaces belong to the command.
            pulseWords[column] = (Array(event.label), simulationClock, simulationClock + duration)
        }
        pendingEvents.removeAll()
        // Event streams are one-shot packets and ignore the coverage; ordinary columns re-draw
        // whether they rain at the end of every pass.
        simulation!.advance(to: simulationClock, coverage: activity.coverage(at: time, density: density),
                            mutationRate: 1 + 2 * mutationPressure)
