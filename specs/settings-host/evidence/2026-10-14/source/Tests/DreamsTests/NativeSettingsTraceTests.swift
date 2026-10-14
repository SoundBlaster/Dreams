import AppKit
import ScreenerKit
import ScreenerScreenCaptureKit
import SwiftUI
import Testing
@testable import Dreams

extension NativeSettingsTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["DREAMS_RECORD_NATIVE_SETTINGS"] == "1"))
    func recordNativeFormsWithScreener() async throws {
        _ = NSApplication.shared
        #expect(Bundle.main.bundleIdentifier != "ru.egormerkushev.dreams")
        let restore = Self.preserveDefaults()
        defer { restore() }
        let page = SettingsPageController(controller: DreamsController(), nativeSettingsEnabled: true)
        page.showControls()
        let model = try #require(page.nativeModel)
        let window = try #require(page.nativeWindow)
        defer { page.cleanUp() }
        let recorder = Screener()
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let traces = ProcessInfo.processInfo.environment["DREAMS_TRACE_DIRECTORY"].map { URL(fileURLWithPath: $0) }
            ?? caches.appending(path: "Screener/Traces")
        let trace = try await recorder.startSession(name: "Dreams-native-settings",
            appBundleID: "ru.egormerkushev.dreams.native-tests", tracesDirectory: traces)
        let backend = ProcessInfo.processInfo.environment["DREAMS_NATIVE_CAPTURE_BACKEND"] ?? "hierarchy"
        try #require(["hierarchy", "screen-capture-kit"].contains(backend), "Unknown native capture backend")
        let capture = ScreenerCaptureSession(screener: recorder)
        func checkpoint(_ section: NativeSettingsSection, name: String, width: CGFloat = 1000, dark: Bool = false) async throws {
            window.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
            window.contentView = NSHostingView(rootView: NativeSettingsPage(model: model, initialSection: section))
            window.setContentSize(NSSize(width: width, height: 720))
            let content = try #require(window.contentView)
            content.layoutSubtreeIfNeeded()
            content.displayIfNeeded()
            try await recorder.mark(name, metadata: ["actions": "model mutations and initial section selection",
                "backend": backend, "inputCoverage": "programmatic states; keyboard input unobserved",
                "width": String(Int(width)), "appearance": dark ? "dark" : "light"])
            if backend == "screen-capture-kit" {
                let source = ScreenCaptureKitWindowSource(windowID: CGWindowID(window.windowNumber))
                try await source.record(to: recorder, reason: name)
            } else {
                try await capture.capture(from: AppKitCaptureSource(view: content), reason: name)
            }
        }
        do {
            for section in NativeSettingsSection.allCases {
                try await checkpoint(section, name: "section." + section.rawValue)
            }
            model.automaticColumns = false
            model.columns = 80
            model[parameter: .density] = 0.6
            model[parameter: .speed] = 0.43
            model.decelerationEnabled = true
            model[parameter: .deceleration] = -24
            model[parameter: .search] = 0.37
            try await checkpoint(.rain, name: "rain.edited.dark", dark: true)
            try await checkpoint(.rain, name: "rain.narrow", width: 560)
            model.transparent = true
            model[parameter: .glow] = 0.12
            try await checkpoint(.background, name: "background.transparent")
            try await checkpoint(.appearance, name: "appearance.transparent.dark", dark: true)
            try await recorder.stopSession()
            print("DREAMS_NATIVE_SETTINGS_TRACE=\(trace.path)")
        } catch {
            try? await recorder.mark("Scenario.failed", metadata: ["error": String(describing: error)])
            try? await recorder.stopSession()
            throw error
        }
    }
}
