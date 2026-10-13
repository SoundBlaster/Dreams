import AppKit
import Carbon.HIToolbox
import MetalKit
import MCP

@main
enum DreamsMain {
    @MainActor
    static func main() {
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
        SettingsMigration.run()
        let publisherOnly = CommandLine.arguments.contains("--publisher")
        let interactive = !CommandLine.arguments.contains("--mcp")
            && !CommandLine.arguments.contains("--lab")
            && !CommandLine.arguments.contains("--render-demo")
        let application = NSApplication.shared
