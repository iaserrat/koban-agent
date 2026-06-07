import Foundation
import OSLog

extension AppDelegate {
    /// Clears the saved sync identity and re-enrolls, then restarts the engine on the result. Runs
    /// through the shared restart guard so it cannot interleave with a file-watcher or remote
    /// reload, and throws when re-enrollment fails or a reload is already in flight, so the Settings
    /// pane shows the failure instead of a false success.
    func resetSyncStateForSettings() async throws {
        do {
            let didReset = try await runGuardedConfigurationReload {
                let configuration = try await SyncIdentityResetter().reset(ConfigurationLoader.load())
                await self.restartEngine(with: configuration)
            }
            guard didReset else { throw SyncResetError.reloadInProgress }
        } catch {
            Log.sync.error("Could not reset sync state: \(error).")
            throw error
        }
    }
}
