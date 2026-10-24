import AppKit
import Testing
@testable import Dreams

@MainActor
struct DesktopInstanceTests {
    @Test(arguments: [
        (["Dreams"], DesktopInstance.Mode.interactive),
        (["Dreams", "--legacy-settings"], .interactive),
        (["Dreams", "--mcp"], .controller),
        (["Dreams", "--lab"], .controller),
        (["Dreams", "--mcp", "--publisher"], .independent),
        (["Dreams", "--mcp", "--render-demo", "/tmp/output"], .controller),
        (["Dreams", "--mcp", "--publisher", "--lab"], .independent),
        (["Dreams", "--render-demo", "/tmp/output", "--lab"], .independent),
        (["Dreams", "--render-demo", "/tmp/output"], .independent),
        (["Dreams", "--performance-run"], .independent),
        (["Dreams", "--performance-calibration"], .independent),
        (["Dreams", "--performance-feed"], .independent),
        (["Dreams", "--hook", "codex"], .independent),
        (["Dreams", "--publish"], .independent),
        (["Dreams", "--hooks-status"], .independent),
        (["Dreams", "--install-hooks"], .independent),
        (["Dreams", "--uninstall-hooks"], .independent),
        (["Dreams", "--fixture-events"], .independent)
    ])
    func launchModesKeepIndependentPublishersAndOfflineTools(arguments: [String], expected: DesktopInstance.Mode) {
        #expect(DesktopInstance.Mode(arguments: arguments) == expected)
    }

    @Test func contendersShareOneLeaseAndReleaseDoesNotReplaceItsInode() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let owner = try DesktopInstance(directory: directory)
        let contender = try DesktopInstance(directory: directory)
        #expect(try owner.acquire())
        #expect(try owner.acquire())
        #expect(try !contender.acquire())
        owner.release()
        #expect(try contender.acquire())
        let third = try DesktopInstance(directory: directory)
        #expect(try !third.acquire())
        contender.release()
        #expect(try third.acquire())
    }

    @Test func processExitReleasesLeaseWithoutRemovingTheLockFile() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let candidate = try DesktopInstance(directory: directory)
        let child = Process()
        child.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        child.arguments = ["python3", "-c", """
            import fcntl, sys
            with open(sys.argv[1], 'r+') as lock:
                fcntl.flock(lock, fcntl.LOCK_EX)
                print('locked', flush=True)
                sys.stdin.readline()
            """, directory.appendingPathComponent("desktop-instance.lock").path]
        let output = Pipe()
        let input = Pipe()
        child.standardOutput = output
        child.standardInput = input
        try child.run()
        defer { if child.isRunning { kill(child.processIdentifier, SIGKILL) } }
        let descriptor = output.fileHandleForReading.fileDescriptor
        try #require(fcntl(descriptor, F_SETFL, O_NONBLOCK) == 0)
        var receipt = ""
        var bytes = [UInt8](repeating: 0, count: 64)
        for _ in 0..<100 {
            let count = Darwin.read(descriptor, &bytes, bytes.count)
            if count > 0 { receipt += String(decoding: bytes.prefix(count), as: UTF8.self) }
            if receipt.contains("locked\n") || !child.isRunning { break }
            try await Task.sleep(for: .milliseconds(50))
        }
        try #require(receipt == "locked\n", "Child lock readiness must arrive within five seconds")
        #expect(try !candidate.acquire())
        child.terminate()
        for _ in 0..<100 {
            if !child.isRunning { break }
            try await Task.sleep(for: .milliseconds(50))
        }
        try #require(!child.isRunning, "Child termination must complete within five seconds")
        #expect(try candidate.acquire())
        #expect(FileManager.default.fileExists(atPath: directory.appendingPathComponent("desktop-instance.lock").path))
    }

    @Test func invalidLockLocationFailsClosed() throws {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data().write(to: path)
        defer { try? FileManager.default.removeItem(at: path) }
        #expect(throws: (any Error).self) { try DesktopInstance(directory: path) }
    }

    @Test func publisherCannotPromoteItselfToASecondGUI() {
        let delegate = DreamsDelegate()
        #expect(!delegate.ownsDesktop)
        delegate.reopenSettings()
        #expect(!delegate.showsControls)
        #expect(!delegate.applicationShouldHandleReopen(NSApplication.shared, hasVisibleWindows: false))
    }
}
