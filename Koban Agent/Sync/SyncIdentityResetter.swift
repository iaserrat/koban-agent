import Foundation

/// Resets the device's sync identity: deletes the saved enrollment, then re-bootstraps so the
/// device enrolls again from its saved sync configuration. The engine restart is left to the
/// caller; this type owns only the delete-and-re-enroll decision so it stays testable without the
/// AppKit app shell.
struct SyncIdentityResetter {
    private let stateStore: EnrollmentStateStore
    private let bootstrap: (KobanConfiguration) async -> KobanConfiguration

    init(
        stateStore: EnrollmentStateStore = EnrollmentStateStore(),
        bootstrap: @escaping (KobanConfiguration) async -> KobanConfiguration = Self.liveBootstrap
    ) {
        self.stateStore = stateStore
        self.bootstrap = bootstrap
    }

    private static func liveBootstrap(_ configuration: KobanConfiguration) async -> KobanConfiguration {
        await SyncBootstrapper().bootstrap(configuration)
    }

    /// Deletes the saved identity and re-bootstraps from `configuration`, returning the effective
    /// configuration to restart the engine on. Throws `SyncResetError.reenrollmentFailed` when sync
    /// expects enrollment but bootstrap could not re-establish it, so the caller surfaces the
    /// failure rather than reporting a clean reset while the device is silently unenrolled.
    func reset(_ configuration: KobanConfiguration) async throws -> KobanConfiguration {
        try stateStore.delete()
        let bootstrapped = await bootstrap(configuration)
        if expectsEnrollment(configuration.sync), try stateStore.load() == nil {
            throw SyncResetError.reenrollmentFailed
        }
        return bootstrapped
    }

    private func expectsEnrollment(_ sync: SyncSettings) -> Bool {
        sync.enabled && sync.enrollmentToken != nil && sync.endpoint != nil
    }
}
