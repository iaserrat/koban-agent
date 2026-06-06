import Foundation

// MARK: - Construction

extension MonitoringEngine {
    static func makeCommitStore(
        database: AppDatabase,
        configuration: KobanConfiguration
    ) -> ScanCommitStore {
        ScanCommitStore(
            database: database,
            retention: StorageRetentionPolicy(settings: configuration.persistence),
            syncSettings: configuration.sync
        )
    }

    static func makePublisher(
        database: AppDatabase,
        configuration: KobanConfiguration,
        collectors: [any SurfaceCollector],
        appState: AppState
    ) -> MonitoringPublisher {
        MonitoringPublisher(
            readModels: ReadModelStore(database: database),
            summaryFactory: SurfaceSummaryFactory.live(configuration: configuration),
            collectors: collectors,
            appState: appState,
            syncEnabled: configuration.sync.enabled,
            deviceID: configuration.sync.deviceID
        )
    }
}
