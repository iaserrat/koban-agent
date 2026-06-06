import OSLog

// MARK: - MonitoringShutdownCoordinator

struct MonitoringShutdownCoordinator {
    let database: AppDatabase

    func checkpointDatabase() {
        do {
            try database.checkpointForShutdown()
        } catch {
            Log.engine.error("Database shutdown checkpoint failed: \(error).")
        }
    }
}
