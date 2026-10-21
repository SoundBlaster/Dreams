import AppKit

/// Appearance recipes only; motion, grid, glyphs and agent settings stay user-owned.
enum NativeAppearancePreset: String, CaseIterable, Identifiable {
    case classic, dimmed, monochrome
    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .classic: settingsString("appearance.classic")
        case .dimmed: settingsString("appearance.dimmed")
        case .monochrome: settingsString("appearance.monochrome")
        }
    }

    func values(transparent: Bool) -> NativeAppearanceValues {
        let green = transparent ? DreamsPreset.transparentRainColor : DreamsPreset.rainColor
        let glow = transparent ? DreamsPreset.transparentGlow : DreamsPreset.glow
        switch self {
        case .classic:
            return NativeAppearanceValues(color: green, glow: glow, spread: DreamsPreset.brightnessSpread,
                                          pulse: DreamsPreset.pulseStrength)
        case .dimmed:
            return NativeAppearanceValues(color: green.map { $0 * 0.65 }, glow: glow * 0.25, spread: 0.3, pulse: 0.1)
        case .monochrome:
            return NativeAppearanceValues(color: Array(repeating: transparent ? 1 : 0.8, count: 3),
                                          glow: transparent ? 0 : 0.15, spread: 0.25, pulse: 0.1)
        }
    }
}

struct NativeAppearanceValues {
    let color: [Double]
    let glow: Double
    let spread: Double
    let pulse: Double

    var nsColor: NSColor { NSColor(srgbRed: color[0], green: color[1], blue: color[2], alpha: 1) }

    func matches(color: NSColor, glow: Double, spread: Double, pulse: Double) -> Bool {
        guard let rgb = color.usingColorSpace(.sRGB) else { return false }
        return zip(self.color + [self.glow, self.spread, self.pulse],
                   [rgb.redComponent, rgb.greenComponent, rgb.blueComponent, glow, spread, pulse])
            .allSatisfy { abs($0 - $1) < 0.0001 }
    }
}

enum NativeRainSwatch: String, CaseIterable, Identifiable {
    case green, lime, cyan, blue, purple, pink, red, white
    var id: Self { self }
    var title: LocalizedStringResource {
        switch self {
        case .green: settingsString("palette.green")
        case .lime: settingsString("palette.lime")
        case .cyan: settingsString("palette.cyan")
        case .blue: settingsString("palette.blue")
        case .purple: settingsString("palette.purple")
        case .pink: settingsString("palette.pink")
        case .red: settingsString("palette.red")
        case .white: settingsString("palette.white")
        }
    }
    var color: NSColor {
        let components: (Double, Double, Double) = switch self {
        case .green: (0, 0.9, 0.3)
        case .lime: (0.5, 1, 0.2)
        case .cyan: (0, 0.9, 0.9)
        case .blue: (0.2, 0.4, 1)
        case .purple: (0.65, 0.2, 1)
        case .pink: (1, 0.2, 0.65)
        case .red: (1, 0.25, 0.3)
        case .white: (1, 1, 1)
        }
        return NSColor(srgbRed: components.0, green: components.1, blue: components.2, alpha: 1)
    }
}
