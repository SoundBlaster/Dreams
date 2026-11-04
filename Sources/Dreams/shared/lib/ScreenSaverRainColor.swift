import Foundation
import ScreenSaver
import simd

enum ScreenSaverRainColor {
    static let module = "ru.egormerkushev.dreams.saver-experiment"
    private static let key = "rainColorSRGB"

    static func write(_ components: [Double], module: String = module) {
        guard valid(components), let defaults = ScreenSaverDefaults(forModuleWithName: module) else { return }
        defaults.set(components, forKey: key)
        defaults.synchronize()
    }

    static func read(module: String = module) -> SIMD3<Float>? {
        guard let defaults = ScreenSaverDefaults(forModuleWithName: module),
              let components = defaults.array(forKey: key) as? [Double],
              valid(components) else { return nil }
        func linear(_ value: Double) -> Float {
            Float(value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4))
        }
        return SIMD3(linear(components[0]), linear(components[1]), linear(components[2]))
    }

    private static func valid(_ values: [Double]) -> Bool {
        values.count == 3 && values.allSatisfy { $0.isFinite && (0...1).contains($0) }
    }
}
