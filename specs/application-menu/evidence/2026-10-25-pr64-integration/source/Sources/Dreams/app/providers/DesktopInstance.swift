import AppKit
import Darwin

/// One desktop owner per user, shared by installed copies and development builds.
@MainActor
final class DesktopInstance {
    enum Mode {
        case interactive, controller, independent

        init(arguments: [String]) {
            let independent = ["--performance-run", "--performance-calibration", "--performance-feed", "--hook",
                "--install-hooks", "--uninstall-hooks", "--hooks-status", "--fixture-events", "--publish"]
            if arguments.contains(where: independent.contains) {
                self = .independent
            } else if arguments.contains("--mcp") {
                self = arguments.contains("--publisher") ? .independent : .controller
            } else if arguments.contains("--render-demo") {
                self = .independent
            } else if arguments.contains("--lab") {
                self = .controller
            } else {
                self = .interactive
            }
        }
    }

    static let reopenNotification = Notification.Name("ru.egormerkushev.dreams.reopenSettings")
    private var descriptor: Int32?
    private var observer: NSObjectProtocol?
    private(set) var isOwner = false

    init(directory: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Dreams", isDirectory: true)) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700])
        let fd = open(directory.appendingPathComponent("desktop-instance.lock").path,
                      O_CREAT | O_RDWR | O_CLOEXEC | O_NOFOLLOW, 0o600)
        guard fd >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        descriptor = fd
    }

    isolated deinit { release() }

    /// Keep the inode in place. Closing the descriptor releases ownership even after a crash.
    func acquire() throws -> Bool {
        guard let descriptor else { throw POSIXError(.EBADF) }
        if isOwner { return true }
        if flock(descriptor, LOCK_EX | LOCK_NB) == 0 { isOwner = true; return true }
        guard errno == EWOULDBLOCK || errno == EAGAIN else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        return false
    }

    func observeReopen(_ action: @escaping @MainActor () -> Void) {
        guard isOwner, observer == nil else { return }
        observer = DistributedNotificationCenter.default().addObserver(
            forName: Self.reopenNotification, object: nil, queue: .main
        ) { _ in MainActor.assumeIsolated { action() } }
    }

    func release() {
        if let observer { DistributedNotificationCenter.default().removeObserver(observer) }
        observer = nil
        if let descriptor { close(descriptor) }
        descriptor = nil
        isOwner = false
    }

    /// Older GUI builds do not hold the lease. Ignore independent accessory publishers.
    static func existingGUI() -> NSRunningApplication? {
        ["ru.egormerkushev.dreams", SettingsMigration.legacyDomain]
            .flatMap { NSRunningApplication.runningApplications(withBundleIdentifier: $0) }
            .first { $0.processIdentifier != getpid() && !$0.isTerminated && $0.activationPolicy == .regular }
    }

    static func requestReopen() {
        // Only the lease owner listens, including an accessory full-control MCP process.
        DistributedNotificationCenter.default().postNotificationName(reopenNotification, object: nil,
            userInfo: nil, deliverImmediately: true)
    }

    static func reopen(_ application: NSRunningApplication?) async throws {
        requestReopen()
        if let url = application?.bundleURL {
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            configuration.createsNewApplicationInstance = false
            _ = try await NSWorkspace.shared.openApplication(at: url, configuration: configuration)
        } else {
            application?.activate(options: [.activateAllWindows])
        }
    }
}
