import AppKit
import MetalKit

@main
enum DreamsMain {
    @MainActor
    static func main() async {
        if CommandLine.arguments.contains("--performance-run") || CommandLine.arguments.contains("--performance-calibration")
            || CommandLine.arguments.contains("--performance-feed") {
            PerformanceRun.run(arguments: CommandLine.arguments)
            return
        }
        if let hookIndex = CommandLine.arguments.firstIndex(of: "--hook") {
            guard CommandLine.arguments.indices.contains(hookIndex + 1) else { return }
            KeywordInput.runHook(source: CommandLine.arguments[hookIndex + 1])
            return
        }
        if CommandLine.arguments.contains("--install-hooks") || CommandLine.arguments.contains("--uninstall-hooks") {
            do {
                let lines = try HooksInstaller.run(uninstall: CommandLine.arguments.contains("--uninstall-hooks"),
                                                   dryRun: CommandLine.arguments.contains("--dry-run"))
                print(lines.joined(separator: "\n"))
            } catch {
                FileHandle.standardError.write(Data("Dreams: \(error.localizedDescription)\n".utf8))
                exit(1)
            }
            return
        }
        if CommandLine.arguments.contains("--hooks-status") {
            for (source, _) in HooksInstaller.targets {
                print("\(source): \(HooksInstaller.state(source: source).rawValue)")
            }
            return
        }
        if CommandLine.arguments.contains("--fixture-events") {
            do { try KeywordInput.publishFixtures() }
            catch {
                FileHandle.standardError.write(Data("Dreams: \(error.localizedDescription)\n".utf8))
                exit(1)
            }
            return
        }
        if CommandLine.arguments.contains("--publish") {
            do { try KeywordInput.runPublish() }
            catch {
                FileHandle.standardError.write(Data("Dreams: \(error.localizedDescription)\n".utf8))
                exit(1)
            }
            return
        }
        let mode = DesktopInstance.Mode(arguments: CommandLine.arguments)
        var instance: DesktopInstance?
        if mode != .independent {
            do {
                let candidate = try DesktopInstance()
                let existing = DesktopInstance.existingGUI()
                let acquired = try (existing == nil && candidate.acquire())
                guard acquired else {
                    if mode == .interactive { try await DesktopInstance.reopen(existing) }
                    else {
                        let message = "Dreams: another desktop instance is running. "
                            + "Use --mcp --publisher for independent event publishing.\n"
                        FileHandle.standardError.write(Data(message.utf8))
                        exit(1)
                    }
                    return
                }
                instance = candidate
            } catch {
                FileHandle.standardError.write(Data("Dreams: cannot acquire or reopen the desktop instance: \(error.localizedDescription)\n".utf8))
                exit(1)
            }
        }
        runDesktop(instance: instance)
    }

    @MainActor
    private static func runDesktop(instance: DesktopInstance?) {
        SettingsMigration.run()
        let publisherOnly = CommandLine.arguments.contains("--publisher")
        let interactive = !CommandLine.arguments.contains("--mcp")
            && !CommandLine.arguments.contains("--lab")
            && !CommandLine.arguments.contains("--render-demo")
        let application = NSApplication.shared
        application.setActivationPolicy(interactive ? .regular : .accessory)
        // The normal app has a Dock icon while it runs: set it explicitly, so it never depends on
        // the icon cache of the Dock or Launch Services (a stale cache shows a blank placeholder).
        if interactive, let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: url) {
            application.applicationIconImage = icon
        }
        let delegate = DreamsDelegate()
        delegate.showsControls = interactive
        delegate.ownsDesktop = instance?.isOwner == true
        application.delegate = delegate
        instance?.observeReopen { [weak delegate] in delegate?.reopenSettings() }
        if !publisherOnly { delegate.setupMenu() }
        if CommandLine.arguments.contains("--mcp") {
            Task {
                do { try await runServer(controller: delegate.controller, publisherOnly: publisherOnly) }
                catch { FileHandle.standardError.write(Data("Dreams: \(error)\n".utf8)) }
                delegate.controller.cleanUp()
                application.terminate(nil)
            }
        } else if let index = CommandLine.arguments.firstIndex(of: "--render-demo") {
            Task {
                do {
                    guard CommandLine.arguments.indices.contains(index + 1) else {
                        throw DreamsError.unavailable("--render-demo requires an output directory.")
                    }
                    let directory = URL(fileURLWithPath: CommandLine.arguments[index + 1], isDirectory: true)
                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                    let renderer = try RainRenderer(view: MTKView(frame: .zero))
                    let activityDemo = CommandLine.arguments.contains("--activity-demo")
                    for frame in 0..<(activityDemo ? 480 : 180) {
                        renderer.demoWorkingAgents = activityDemo
                            ? (frame < 120 ? 3 : frame < 180 ? 1 : frame < 330 ? 0 : 2) : 3
                        let data = try await renderer.previewPNG(posedTime: Float(frame) / 30)
                        try data.write(to: directory.appendingPathComponent(String(format: "%04d.png", frame)))
                    }
                } catch {
                    FileHandle.standardError.write(Data("Dreams render: \(error)\n".utf8))
                    exit(1)
                }
                application.terminate(nil)
            }
        } else if CommandLine.arguments.contains("--lab") {
            Task {
                do { try await delegate.controller.createWorkspace() }
                catch { delegate.show(error: error) }
            }
        }
        withExtendedLifetime((delegate, instance)) { application.run() }
    }

}
