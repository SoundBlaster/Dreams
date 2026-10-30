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
        let policy = NSApp.activationPolicy()
        let appearance = NSApp.appearance
        NSApp.setActivationPolicy(.regular)
        defer { NSApp.setActivationPolicy(policy); NSApp.appearance = appearance }
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
        let backend = ProcessInfo.processInfo.environment["DREAMS_NATIVE_CAPTURE_BACKEND"] ?? "hierarchy"
        let language = ProcessInfo.processInfo.environment["DREAMS_LANGUAGE"] ?? "system"
        let mode = ProcessInfo.processInfo.environment["DREAMS_NATIVE_TRACE_MODE"] ?? "full"
        try #require(["hierarchy", "screen-capture-kit"].contains(backend), "Unknown native capture backend")
        try #require(["full", "metal"].contains(mode), "Unknown native trace mode")
        try #require(mode != "metal" || backend == "screen-capture-kit", "Metal trace requires compositor capture")
        let trace = try await recorder.startSession(name: mode == "metal" ? "Dreams-Metal-preview" : "Dreams-native-settings",
            appBundleID: "ru.egormerkushev.dreams.native-tests", tracesDirectory: traces)
        let capture = ScreenerCaptureSession(screener: recorder)
        model[parameter: .idle] = 1
        model.preview.isPlaying = true
        func checkpoint(_ section: NativeSettingsSection, name: String, width: CGFloat = 1000, height: CGFloat = 720,
                        dark: Bool = false, increasedContrast: Bool = false, recording: Bool = false, shortcutError: Bool = false,
                        largeText: Bool = false, reuseContent: Bool = false) async throws {
            window.appearance = NSAppearance(named: increasedContrast
                ? (dark ? .accessibilityHighContrastDarkAqua : .accessibilityHighContrastAqua)
                : (dark ? .darkAqua : .aqua))
            NSApp.appearance = window.appearance
            if !reuseContent {
                window.contentView = NSHostingView(rootView: NativeSettingsPage(model: model, initialSection: section)
                    .environment(\.colorScheme, dark ? .dark : .light)
                    .environment(\.dynamicTypeSize, largeText ? .accessibility5 : .large)
                    .font(largeText ? .system(size: 32) : .body))
            }
            window.setFrame(NSRect(origin: window.frame.origin, size: NSSize(width: width, height: height)), display: true)
            if recording { model.recordShortcut() }
            if shortcutError { page.shortcutRecorder.message = L("hotkey.taken", "⌃⌥⌘F17") }
            let content = try #require(window.contentView)
            content.layoutSubtreeIfNeeded()
            content.displayIfNeeded()
            if backend == "screen-capture-kit" {
                try await Self.pumpPreviewEvents(milliseconds: 150)
                try #require(model.preview.renderer != nil, "Metal preview renderer did not initialize")
                try #require((model.preview.renderer?.framesRendered ?? 0) > 0, "Metal preview did not render")
            }
            try await recorder.mark(name, metadata: ["actions": "model mutations and initial section selection",
                "backend": backend, "previewFrames": String(model.preview.renderer?.framesRendered ?? 0),
                "inputCoverage": "programmatic states; keyboard input unobserved",
                "width": String(Int(width)), "height": String(Int(height)), "geometry": "window frame",
                "language": language, "appearance": dark ? "dark" : "light", "previewPlaying": String(model.preview.isPlaying),
                "increasedContrast": String(increasedContrast), "largeText": String(largeText)])
            if backend == "screen-capture-kit" {
                let source = ScreenCaptureKitWindowSource(windowID: CGWindowID(window.windowNumber))
                try await source.record(to: recorder, reason: name)
            } else {
                try await capture.capture(from: AppKitCaptureSource(view: content), reason: name)
            }
        }
        do {
            if mode == "metal" {
                model.automaticColumns = false
                model.columns = 80
                model[parameter: .density] = 0.6
                try await checkpoint(.rain, name: "metal.rain.playing", dark: true)
                let renderer = try #require(model.preview.renderer)
                model.preview.isPlaying = false
                try await checkpoint(.rain, name: "metal.rain.paused", dark: true, reuseContent: true)
                try #require(model.preview.renderer === renderer, "Pause replaced the preview renderer")
                let pausedFrames = renderer.framesRendered
                model.preview.isPlaying = true
                try await checkpoint(.rain, name: "metal.rain.resumed", dark: true, reuseContent: true)
                try #require(model.preview.renderer === renderer, "Resume replaced the preview renderer")
                try #require(renderer.framesRendered > pausedFrames, "Preview did not render after resume")
                try await checkpoint(.appearance, name: "metal.appearance", dark: true)
                try await recorder.stopSession()
                print("DREAMS_NATIVE_SETTINGS_TRACE=\(trace.path)")
                return
            }
            for section in NativeSettingsSection.allCases {
                try await checkpoint(section, name: "section." + section.rawValue)
                try await checkpoint(section, name: "section." + section.rawValue + ".narrow", width: 560)
            }
            try await checkpoint(.appearance, name: "appearance.large-text.narrow", width: 560, largeText: true)
            for preset in NativeAppearancePreset.allCases {
                model.applyAppearance(preset)
                try await checkpoint(.appearance, name: "appearance.preset." + preset.rawValue, dark: true)
            }
            model.applyColor(.blue)
            try await checkpoint(.appearance, name: "appearance.palette.blue", dark: true)
            try await checkpoint(.appearance, name: "appearance.palette.narrow", width: 560, dark: true)
            model[parameter: .pulse] = 0.77
            try await checkpoint(.appearance, name: "appearance.custom", dark: true)
            try await checkpoint(.rain, name: "rain.large-text.narrow", width: 560, largeText: true)
            try await checkpoint(.general, name: "shortcut.recording", recording: true)
            model.cancelShortcutRecording()
            try await checkpoint(.general, name: "shortcut.error.narrow", width: 560, shortcutError: true)
            model.cancelShortcutRecording()
            model.automaticColumns = false
            model.columns = 80
            model[parameter: .density] = 0.6
            model[parameter: .speed] = 0.43
            model.decelerationEnabled = true
            model[parameter: .deceleration] = -24
            model[parameter: .search] = 0.37
            try await checkpoint(.rain, name: "rain.edited.dark", dark: true)
            try await checkpoint(.rain, name: "rain.edited.light")
            try await checkpoint(.rain, name: "rain.expanded.light", width: 1440)
            try await checkpoint(.rain, name: "rain.expanded.dark", width: 1440, dark: true)
            try await checkpoint(.rain, name: "rain.minimum.light", width: 560, height: 450)
            try await checkpoint(.rain, name: "rain.minimum.dark", width: 560, height: 450, dark: true)
            try await checkpoint(.rain, name: "rain.narrow", width: 560)
            model.preview.isPlaying = false
            try await checkpoint(.rain, name: "rain.paused.dark", dark: true)
            try await checkpoint(.rain, name: "rain.increased-contrast.dark", dark: true, increasedContrast: true)
            model.preview.isPlaying = true
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
