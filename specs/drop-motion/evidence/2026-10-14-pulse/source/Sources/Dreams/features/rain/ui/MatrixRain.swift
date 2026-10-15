import AppKit
import CoreText
import Metal

/// Instanced fixed glyphs: independent cursors type downward into a persistent grid.
@MainActor
final class MatrixRain {
    struct Cell {
        var rect: SIMD4<Float>
        var uv: SIMD4<Float>
        var color: SIMD4<Float>
    }
    private let device: any MTLDevice
    private let transparentBackground: Bool
    private let pipeline: any MTLRenderPipelineState
    private let glowPipeline: any MTLRenderPipelineState
    private let atlas: any MTLTexture
    private let glowAtlas: any MTLTexture
    private var glyphs: [String: SIMD4<Float>] = [:]
    private let matrixFont: NSFont
    private let wordFont: NSFont
    private let feed = KeywordFeed()
    private var messages: [KeywordMessage] = []
    private var nextRefresh = 0.0
    private let began = ProcessInfo.processInfo.systemUptime
    private var selections: [Int: (session: String, characters: [Character], color: SIMD4<Float>)] = [:]
    private var selectionCycle = -1
    private var simulation: MatrixSimulation?
    private var activity = RainActivity()
    private var seenEvents = Set<UUID>()
    /// Newest message time already answered with a surge; older messages never flood.
    private var lastMessageUpdate = Date()
    private var surgePending = false
    private var pendingEvents: [KeywordMessage.RainEvent] = []
    private var pulseWords: [Int: (characters: [Character], began: Double, ends: Double)] = [:]
    private var eventColumn = 0
    private var actionPressure = 0.0
    private var mutationPressure = 0.0
    private var lastFrameTime: Double?
    private var simulationClock = 0.0
    // Repertoire from cassmtnr/MatrixDigitalRain (MIT; see THIRD_PARTY_NOTICES.md).
    private let symbols: [Character]

    init(device: any MTLDevice, library: any MTLLibrary, restoredGlyphs: Bool = false,
         transparentBackground: Bool = false) throws {
        self.device = device
        self.transparentBackground = transparentBackground
        if let url = Bundle.module.url(forResource: "DreamsMatrix", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
        guard let wordFont = NSFont(name: "DreamsMatrix-Regular", size: 26) else {
            throw DreamsError.unavailable(L("error.wordFontMissing"))
        }
        let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ".utf16)
        var letterGlyphs = [CGGlyph](repeating: 0, count: letters.count)
        guard CTFontGetGlyphsForCharacters(wordFont, letters, &letterGlyphs, letters.count),
              letterGlyphs.allSatisfy({ $0 != 0 }) else {
            throw DreamsError.unavailable(L("error.wordFontLetters"))
        }
        self.wordFont = wordFont
        let resource = restoredGlyphs ? "DreamsMatrix" : "Matrix-Code"
        if let url = Bundle.module.url(forResource: resource, withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
        if restoredGlyphs {
            guard let font = NSFont(name: "DreamsMatrix-Regular", size: 26) else {
                throw DreamsError.unavailable(L("error.restoredFontMissing"))
            }
            // The font is the repertoire: adding a glyph needs no Swift range edit.
            let characterSet = CTFontCopyCharacterSet(font)
            let codes = (0xE001...0xF8FF).compactMap { value -> UniChar? in
                let code = UniChar(value)
                return CFCharacterSetIsCharacterMember(characterSet, code) ? code : nil
            }
            var mapped = [CGGlyph](repeating: 0, count: codes.count)
            guard !codes.isEmpty,
                  CTFontGetGlyphsForCharacters(font, codes, &mapped, codes.count),
                  mapped.allSatisfy({ $0 != 0 }) else {
                throw DreamsError.unavailable(L("error.restoredFontGlyphs"))
            }
            matrixFont = font
            symbols = codes.map { Character(UnicodeScalar($0)!) }
        } else {
            matrixFont = NSFont(name: "Matrix-Code", size: 26)
                ?? NSFont.monospacedSystemFont(ofSize: 25, weight: .medium)
            symbols = Array("モエヤキオカ7ケサスz152ヨタワ4ネヌナ98ヒ0ホア3ウセ¦:\"꞊ミラリ╌ツテニハソ▪コシマムメー©*+<>|\u{E937}")
        }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "matrixVertex")
        descriptor.fragmentFunction = library.makeFunction(name: "matrixFragment")
        let color = descriptor.colorAttachments[0]!
        color.pixelFormat = transparentBackground ? .bgra8Unorm : .bgra8Unorm_srgb
        color.isBlendingEnabled = true
        color.sourceRGBBlendFactor = .sourceAlpha
        color.destinationRGBBlendFactor = .oneMinusSourceAlpha
        color.sourceAlphaBlendFactor = .one
        color.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        // Scattered light adds to neighbouring halos instead of darkening them.
        color.destinationRGBBlendFactor = .one
        color.destinationAlphaBlendFactor = .one
        glowPipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        let texture = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Unorm,
            width: 2048, height: 2048, mipmapped: false)
        texture.storageMode = .shared
        texture.usage = .shaderRead
        guard let atlas = device.makeTexture(descriptor: texture),
              let glowAtlas = device.makeTexture(descriptor: texture) else {
            throw DreamsError.unavailable("Cannot allocate the glyph atlas.")
        }
        self.atlas = atlas
        self.glowAtlas = glowAtlas
        _ = glyph("?", keyword: true)
        for symbol in symbols { _ = glyph(String(symbol), keyword: false) }
    }

    func draw(encoder: any MTLRenderCommandEncoder, resolution: SIMD2<Float>, brightness: Float,
              previewTime: Float? = nil, demoWorkingAgents: Int? = nil, columnCount: Int = 0, density: Double = 0.8,
              fadeRows: Double = 1, speed: Double = 1, brightnessSpread: Double = 1, glow: Double = 1, idleIntensity: Double = 0.2,
              deceleration: MatrixSimulation.Deceleration = .init(), searchFraction: Double = 0.1,
              pulseStrength: Double = 0.3,
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
                // A drop's pale head is independent of its trail's random ink.
                let head = simulation!.headIntensity(column: column, row: row)
                let mutation = Float(max(0, 1 - (simulationClock - cell.flashedAt) / 0.28))
                let white = max(head, mutation * 0.85)
                let wordIndex = row - wordStart
                // Keywords are typed by the same cursor, not faded over an existing column.
                let isKeyword = selection != nil && wordIndex >= 0
                    && wordIndex < selection!.characters.count && cell.writtenAt >= (pulse?.began ?? Double(cycle * 16))
                // Packet gaps stay empty in the trail, but cannot hide the drop itself.
                guard !cell.isGap || isKeyword || head > 0 else { continue }
                let text: String
                var rgb: SIMD3<Float>
                if isKeyword && keywordBrightness <= 0.001 { continue }
                let pulsedInk = ink * GlyphPulse.gain(at: time, column: column, row: row, strength: pulseStrength)
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
                    rgb = keywordTint * pulsedInk * inkOpacity
                } else {
                    text = String(symbols[cell.glyph])
                    let tint = rainTint + SIMD3<Float>(0, 0, 0.02 * cell.warmth)
                    rgb = tint * pulsedInk * inkOpacity
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
                    (Float(row) - 0.16) / Float(rows), width / Float(columns), 1.32 / Float(rows))
                // A padded tile leaves room for the broad, low-intensity light skirt.
                let glowUV = SIMD4(uv.x - 18.0 / 2048, uv.y - 18.0 / 2048,
                    64.0 / 2048, 64.0 / 2048)
                let glowRect = SIMD4(rect.x - rect.z * 18 / 28, rect.y - rect.w * 18 / 28,
                    rect.z * 64 / 28, rect.w * 64 / 28)
                // The rain's halo follows its colour, a few times brighter than the letters.
                let haloTint = (isKeyword ? keywordTint : (rainTint * 2.4).clamped(lowerBound: .zero, upperBound: SIMD3<Float>(repeating: 1))) * (1 - white)
                    + SIMD3<Float>(0.52, 0.95, 0.65) * white
                if glow > 0 { halos.append(Cell(rect: glowRect, uv: glowUV,
                    color: SIMD4(haloTint * exposure * wordExposure,
                        (0.30 * pulsedInk * inkOpacity + 0.75 * white) * glyphAlpha * Float(min(3, glow))))) }
                cells.append(Cell(rect: rect, uv: uv, color: SIMD4(rgb * exposure, glyphAlpha)))
            }
        }
        guard !cells.isEmpty else { return }
        encoder.setRenderPipelineState(glowPipeline)
        encode(halos, texture: glowAtlas, encoder: encoder, time: t, noise: 0, diffuse: true)
        encoder.setRenderPipelineState(pipeline)
        encode(cells, texture: atlas, encoder: encoder, time: t, noise: 0.7)
    }

    private func encode(_ cells: [Cell], texture: any MTLTexture, encoder: any MTLRenderCommandEncoder,
                        time: Float, noise: Float, diffuse: Bool = false) {
        guard !cells.isEmpty else { return }
        let buffer = cells.withUnsafeBytes { bytes in
            device.makeBuffer(bytes: bytes.baseAddress!, length: bytes.count, options: .storageModeShared)
        }
        guard let buffer else { return }
        encoder.setVertexBuffer(buffer, offset: 0, index: 0)
        encoder.setFragmentTexture(texture, index: 0)
        var parameters = SIMD4<Float>(time, noise, diffuse ? 1 : 0, transparentBackground ? 1 : 0)
        encoder.setFragmentBytes(&parameters, length: MemoryLayout<SIMD4<Float>>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: cells.count)
    }

    private func hash(_ n: Float) -> Float {
        let value = sin(n * 127.1) * 43758.5453
        return value - floor(value)
    }

    private func glyph(_ text: String, keyword: Bool) -> SIMD4<Float> {
        let key = (keyword ? "word:" : "code:") + text
        if let cached = glyphs[key] { return cached }
        guard glyphs.count < 1024 else { return glyphs["word:?"]! }
        let width = 64, height = 64
        let font = keyword ? wordFont : matrixFont
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text,
            attributes: [.font: font, .foregroundColor: NSColor.white]))
        var ascent: CGFloat = 0, descent: CGFloat = 0
        let lineWidth = CTLineGetTypographicBounds(line, &ascent, &descent, nil)
        var pixels = [UInt8](repeating: 0, count: width * height)
        pixels.withUnsafeMutableBytes { bytes in
            guard let context = CGContext(data: bytes.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return }
            context.textPosition = CGPoint(x: (CGFloat(width) - lineWidth) / 2,
                y: (CGFloat(height) - ascent - descent) / 2 + descent)
            CTLineDraw(line, context)
        }
        let index = glyphs.count
        let x = index % 32 * width, y = index / 32 * height
        pixels.withUnsafeBytes { bytes in
            atlas.replace(region: MTLRegionMake2D(x, y, width, height), mipmapLevel: 0,
                withBytes: bytes.baseAddress!, bytesPerRow: width)
        }
        // Computed once per glyph, never per animation frame.
        let near = blur(pixels, width: width, height: height, sigma: 2.8)
        let far = blur(pixels, width: width, height: height, sigma: 6.5)
        let blurred = zip(near, far).map { UInt8(0.40 * Float($0) + 0.60 * Float($1)) }
        blurred.withUnsafeBytes { bytes in
            glowAtlas.replace(region: MTLRegionMake2D(x, y, width, height), mipmapLevel: 0,
                withBytes: bytes.baseAddress!, bytesPerRow: width)
        }
        // Bitmap memory and Metal UVs both start at the top row. Keep V positive:
        // the letters must stay upright. Crop only the empty cell margins.
        let uv = SIMD4(Float(x + 18) / 2048, Float(y + 18) / 2048, 28.0 / 2048, 28.0 / 2048)
        glyphs[key] = uv
        return uv
    }

    private func blur(_ pixels: [UInt8], width: Int, height: Int, sigma: Float) -> [UInt8] {
        let radius = Int(ceil(sigma * 2.5))
        let weights = (-radius...radius).map { exp(-Float($0 * $0) / (2 * sigma * sigma)) }
        let total = weights.reduce(0, +)
        var horizontal = [Float](repeating: 0, count: pixels.count)
        var result = [UInt8](repeating: 0, count: pixels.count)
        for y in 0..<height {
            for x in 0..<width {
                for dx in -radius...radius where (0..<width).contains(x + dx) {
                    horizontal[y * width + x] += Float(pixels[y * width + x + dx]) * weights[dx + radius] / total
                }
            }
        }
        for y in 0..<height {
            for x in 0..<width {
                var value: Float = 0
                for dy in -radius...radius where (0..<height).contains(y + dy) {
                    value += horizontal[(y + dy) * width + x] * weights[dy + radius] / total
                }
                result[y * width + x] = UInt8(min(255, value * 2.2))
            }
        }
        return result
    }
}
