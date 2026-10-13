// Sources/Dreams/MatrixRain.swift:117-278
    func draw(encoder: any MTLRenderCommandEncoder, resolution: SIMD2<Float>, brightness: Float,
              previewTime: Float? = nil, demoWorkingAgents: Int? = nil, columnCount: Int = 0, density: Double = 0.8,
              fadeRows: Double = 1, speed: Double = 1, brightnessSpread: Double = 1, glow: Double = 1, idleIntensity: Double = 0.2,
              deceleration: MatrixSimulation.Deceleration = .init(), searchFraction: Double = 0.1,
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
        simulation!.setSearchFraction(searchFraction)
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
        let cycle = Int(simulationClock / 16)
        if cycle != selectionCycle || selections.isEmpty {
            selections.removeAll()
            let words = (0..<6).flatMap { index in
                active.compactMap { m -> (KeywordMessage, String)? in
                    m.words.indices.contains(index) ? (m, m.words[index]) : nil
                }
            }
            if !words.isEmpty {
                for slot in 0..<min(3, words.count) {
                    let (message, word) = words[(cycle * 3 + slot) % words.count]
                    let column = (columns / 6 + slot * columns / 3 + cycle * 13) % columns
                    selections[column] = (message.sessionID, Array(word.uppercased().filter { !$0.isWhitespace }), message.rgb)
                }
            }
            selectionCycle = cycle
        }
        selections = selections.filter { selection in active.contains { $0.sessionID == selection.value.session } }
        var cells: [Cell] = []
        var halos: [Cell] = []
        cells.reserveCapacity(columns * 32)
        let exposure = max(0.15, brightness / 0.18) * (0.35 + 0.65 * activity.workBlend(at: time))
        for column in 0..<columns {
            guard simulation!.columns[column].isEnabled else { continue }
            let pulse = pulseWords[column]
            let selection = pulse.map { (session: "event", characters: $0.characters, color: SIMD4<Float>(0, 0, 0, 1)) }
                ?? selections[column]
            let lastStart = max(2, rows - (selection?.characters.count ?? 8) - 2)
            // A hook's first character belongs to the new head at the top of the screen.
            let wordStart = pulse != nil ? 0 : 2 + Int(hash(Float(column + cycle * 31)) * Float(lastStart - 2))
            for row in 0..<rows {
                let cell = simulation!.columns[column].cells[row]
                let ink = cell.ink(brightnessSpread: brightnessSpread)
                let visibility = cell.visibility
                let opacity = simulation!.opacity(column: column, row: row)
                guard cell.glyph >= 0, opacity > 0.008 else { continue }
                // Over windows, dissolve the coverage instead of leaving an opaque black stroke.
                let inkOpacity: Float = transparentBackground ? 1 : opacity
                let glyphAlpha = visibility * (transparentBackground ? opacity : 1)
                let head = simulation!.headIntensity(column: column, row: row)
                    * (cell.ink > 0.45 ? 1 : 0.2)
                let mutation = Float(max(0, 1 - (simulationClock - cell.flashedAt) / 0.28))
                let white = max(head, mutation * 0.85)
                let wordIndex = row - wordStart
                // Keywords are typed by the same cursor, not faded over an existing column.
                let isKeyword = selection != nil && wordIndex >= 0
                    && wordIndex < selection!.characters.count && cell.writtenAt >= (pulse?.began ?? Double(cycle * 16))
                guard !cell.isGap || isKeyword else { continue }
                let text: String
                var rgb: SIMD3<Float>
                if isKeyword && keywordBrightness <= 0.001 { continue }
                // Keyword cells mutate like the rain around them: while the simulation searches
                // a cell (or just swapped it), a rain glyph flickers there in the keyword colour,
                // then the letter returns. Only the colour sets words apart.
                let search = simulation!.columns[column].searches[row]
                let mutating = isKeyword && cell.glyph >= 0
                    && ((search?.row == row && search?.writtenAt == cell.writtenAt)
                        || (cell.changedAt > cell.writtenAt && simulationClock - cell.changedAt < 0.15))
                if isKeyword, let selection {
                    text = mutating ? String(symbols[cell.glyph]) : String(selection.characters[wordIndex])
                    // Same ink as the rain (brightness spread included); colour and the
                    // word brightness setting are the only differences.
                    rgb = keywordTint * ink * inkOpacity
                } else {
                    text = String(symbols[cell.glyph])
                    let tint = rainTint + SIMD3<Float>(0, 0, 0.02 * cell.warmth)
                    rgb = tint * ink * inkOpacity
                }
                // Only the newly printed cell is pale; older signs keep their own ink level.
                rgb = rgb * (1 - white) + SIMD3<Float>(0.86, 0.96, 0.88) * white
                let wordExposure: Float = isKeyword ? Float(min(2, max(0, keywordBrightness))) : 1
                rgb *= wordExposure
                let uv = glyph(text, keyword: isKeyword && !mutating)
                // Atlas cells have internal side bearings: let quads overlap those empty
                // margins so visible ink nearly touches while glyphs remain large.
                // Film reference: 22:30 versus the font's 38:46. Narrow the ink
                // around the cell center, keeping row spacing and glyph height.
                let width: Float = 1.30 * (22.0 / 30.0) / (38.0 / 46.0)
                let rect = SIMD4<Float>((Float(column) + (1 - width) / 2) / Float(columns),
