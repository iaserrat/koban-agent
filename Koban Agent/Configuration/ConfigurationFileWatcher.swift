import Foundation

/// Watches `~/.config/koban/` for changes to `koban.yaml` and fires `onChange` so the Settings
/// UI and the running engine can pick up edits made outside the app (or our own writes echoing
/// back). FSEvents watches directories, so we watch the parent and filter to our file.
///
/// `@unchecked Sendable` is justified the same way as `WatchCoordinator`: the only mutable state
/// is `watcher`, mutated solely in `start()`/`stop()` (called from the main actor that owns this),
/// and the escaping callback captures only immutable values.
final class ConfigurationFileWatcher: @unchecked Sendable {
    private let directory: URL
    private let fileName: String
    private let latency: TimeInterval
    private let onChange: @Sendable () -> Void
    private var watcher: FSEventsWatcher?

    init(
        fileURL: URL = ConfigPaths.userConfigFile(),
        latency: TimeInterval = ConfigurationDefaults.configurationWatchLatencySeconds,
        onChange: @escaping @Sendable () -> Void
    ) {
        directory = fileURL.deletingLastPathComponent()
        fileName = fileURL.lastPathComponent
        self.latency = latency
        self.onChange = onChange
    }

    @discardableResult
    func start() -> Bool {
        guard watcher == nil else { return true }
        let watcher = FSEventsWatcher(
            paths: [directory.path],
            latency: latency
        ) { [fileName, onChange] events in
            let touchedFile = events.contains { ($0.path as NSString).lastPathComponent == fileName }
            guard touchedFile else { return }
            onChange()
        }
        guard watcher.start() else { return false }
        self.watcher = watcher
        return true
    }

    func stop() {
        watcher?.stop()
        watcher = nil
    }
}
