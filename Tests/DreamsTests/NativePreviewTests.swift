import AppKit
import MetalKit
import SwiftUI
import Testing
@testable import Dreams

extension NativeSettingsTests {
    @Test func backdropKeepsOneSurfaceAcrossAdaptiveLayout() async throws {
        _ = NSApplication.shared
        let page = SettingsPageController(controller: DreamsController(), nativeSettingsEnabled: true)
        let model = NativeSettingsModel(owner: page)
        let host = NSHostingView(rootView: NativeSettingsPage(model: model))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1000, height: 720),
                              styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        window.contentView = host
        defer { window.contentView = nil; page.cleanUp() }
        func surfaces(in view: NSView) -> [RainPreviewView] {
            (view as? RainPreviewView).map { [$0] } ?? view.subviews.flatMap { surfaces(in: $0) }
        }
        host.layoutSubtreeIfNeeded()
        let initial = try #require(surfaces(in: host).first)
        for width in [560, 1100, 560] {
            window.setContentSize(NSSize(width: width, height: 720))
            host.layoutSubtreeIfNeeded()
            await Task.yield()
            host.layoutSubtreeIfNeeded()
            let current = surfaces(in: host)
            #expect(current.count == 1, "The form and opening must share one Metal surface")
            #expect(current.first === initial, "Changing layout must not replace the playback surface")
            #expect(initial.frame.width > 0 && initial.frame.height > 0)
        }
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["DREAMS_TEST_METAL"] == "1"),
          arguments: [0, 80], [1, 2])
    func previewIsAPixelExactScreenCrop(columns: Int, scale: Int) async throws {
        _ = try #require(ProcessInfo.processInfo.environment["DREAMS_FEED_DIRECTORY"])
        let screen = SIMD2(800 * scale, 600 * scale)
        let crop = SIMD2(320 * scale, 200 * scale)
        func renderer() throws -> RainRenderer {
            let renderer = try RainRenderer(view: MTKView())
            renderer.rainColumnCount = columns
            renderer.rainDensity = 1
            renderer.rainIdleIntensity = 1
            renderer.rainSearchFraction = 0
            renderer.rainGlow = 0
            return renderer
        }
        let full = try await renderer().previewPNG(posedTime: 6, pixelSize: screen)
        let preview = try await renderer().previewPNG(posedTime: 6, pixelSize: crop,
            referenceSize: CGSize(width: screen.x, height: screen.y))
        let large = try #require(NSBitmapImageRep(data: full))
        let small = try #require(NSBitmapImageRep(data: preview))
        try #require(large.bitsPerPixel == small.bitsPerPixel && !large.isPlanar && !small.isPlanar)
        let fullBytes = try #require(large.bitmapData)
        let cropBytes = try #require(small.bitmapData)
        let rowBytes = crop.x * small.bitsPerPixel / 8
        var differentRows = 0
        var visible = false
        for row in 0..<crop.y {
            let expected = UnsafeBufferPointer(start: fullBytes + row * large.bytesPerRow, count: rowBytes)
            let actual = UnsafeBufferPointer(start: cropBytes + row * small.bytesPerRow, count: rowBytes)
            if !expected.elementsEqual(actual) { differentRows += 1 }
            if !visible {
                for x in 0..<crop.x where (small.colorAt(x: x, y: row)?.greenComponent ?? 0) > 0.05 {
                    visible = true
                    break
                }
            }
        }
        #expect(visible, "The comparison must include visible glyphs")
        #expect(differentRows == 0, "Preview must crop the screen-sized viewport without shrinking glyphs")
    }

    @Test func previewIsLazyAndDoesNotRequestAnOverlay() throws {
        _ = NSApplication.shared
        let controller = DreamsController()
        let session = RainPreviewSession(controller: controller)
        session.isPlaying = true
        session.refresh()
        #expect(session.renderer == nil)
        #expect(try controller.status()["rain_requested"] as? Bool == false)
        session.reduceMotionChanged(true)
        #expect(!session.isPlaying)
        session.reduceMotionChanged(false)
        #expect(!session.isPlaying)
        session.isPlaying = true
        #expect(session.isPlaying)
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["DREAMS_TEST_METAL"] == "1"))
    func previewUsesSharedSettingsAndReleasesItsRendererWhenHidden() async throws {
        _ = NSApplication.shared
        let restore = Self.preserveDefaults()
        defer { restore() }
        let controller = DreamsController()
        try controller.setTransparentBackground(false)
        let page = SettingsPageController(controller: controller, nativeSettingsEnabled: true)
        let model = NativeSettingsModel(owner: page)
        page.nativeModel = model
        defer { page.cleanUp() }
        let session = model.preview
        let view = MTKView(frame: NSRect(x: 0, y: 0, width: 640, height: 400))
        view.wantsLayer = true
        session.attach(view)
        #expect(session.renderer == nil)
        session.setVisible(true)
        #expect(session.errorMessage == nil)
        #expect(session.renderer != nil)
        session.isPlaying = false
        #expect(view.isPaused)
        let time = session.time
        session.draw(in: view)
        #expect(session.time == time)
        model[parameter: .speed] = 0.43
        model[parameter: .density] = 0.7
        model[parameter: .pulse] = 0.8
        model.columns = 48
        #expect(session.renderer?.rainSpeed == 0.43)
        #expect(session.renderer?.rainDensity == 0.7)
        #expect(session.renderer?.rainPulseStrength == 0.8)
        #expect(session.renderer?.rainColumnCount == 48)
        session.isPlaying = true
        session.draw(in: view)
        let runningTime = session.time
        try await Task.sleep(for: .milliseconds(20))
        model[parameter: .speed] = 0.61
        session.draw(in: view)
        #expect(session.time > runningTime, "Editing a slider must not reset the preview clock each frame")
        let first = try await #require(session.renderer).previewPNG(posedTime: 6)
        controller.rainSpeed = 0.91
        #expect(session.renderer?.rainSpeed == 0.91)
        let opaque = ObjectIdentifier(try #require(session.renderer))
        model.transparent = true
        #expect(ObjectIdentifier(try #require(session.renderer)) != opaque)
        #expect(view.colorPixelFormat == .bgra8Unorm)
        model[parameter: .glow] = 0.12
        #expect(session.renderer?.rainGlow == 0.12)
        let second = try await #require(session.renderer).previewPNG(posedTime: 6)
        #expect(first != second)
        let glyphs = ObjectIdentifier(try #require(session.renderer))
        model.restoredGlyphs.toggle()
        #expect(ObjectIdentifier(try #require(session.renderer)) != glyphs)
        #expect(try controller.status()["rain_requested"] as? Bool == false)
        session.setVisible(false)
        #expect(session.renderer == nil && view.isPaused && view.delegate == nil)
        session.refresh()
        #expect(session.renderer == nil)
        session.setVisible(true)
        #expect(session.renderer != nil)
        session.detach(view)
        #expect(session.renderer == nil && view.delegate == nil)
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["DREAMS_TEST_METAL"] == "1"))
    func dismantlingAnOldSurfaceDoesNotStopItsReplacement() throws {
        _ = NSApplication.shared
        let controller = DreamsController()
        let session = RainPreviewSession(controller: controller)
        let old = MTKView(frame: .zero)
        let replacement = MTKView(frame: .zero)
        session.attach(old)
        session.setVisible(true)
        session.attach(replacement)
        #expect(old.delegate == nil && old.isPaused)
        session.setVisible(true)
        session.detach(old)
        session.visibilityChanged(false, for: old)
        #expect(session.isVisible && session.renderer != nil)
        session.detach(replacement)
        #expect(session.renderer == nil && !session.isVisible)
    }
    /// SwiftPM tests do not run NSApplication.run; drain native window/display events explicitly.
    static func pumpPreviewEvents(milliseconds: Int) async throws {
        drainPreviewEvents(milliseconds: milliseconds)
        try await Task.sleep(for: .milliseconds(150))
    }

    private static func drainPreviewEvents(milliseconds: Int) {
        let deadline = Date().addingTimeInterval(Double(milliseconds) / 1000)
        while Date() < deadline {
            if let event = NSApp.nextEvent(matching: .any, until: deadline, inMode: .default, dequeue: true) {
                NSApp.sendEvent(event)
            }
        }
    }

}
