import Foundation

// MARK: - ScanHealthRecorder

struct ScanHealthRecorder {
    let markScanStarted: @Sendable (MonitoredSurface, Date) throws -> Void
    let markScanFailed: @Sendable (MonitoredSurface, any Error, Date) throws -> Void

    init(
        markScanStarted: @escaping @Sendable (MonitoredSurface, Date) throws -> Void,
        markScanFailed: @escaping @Sendable (MonitoredSurface, any Error, Date) throws -> Void
    ) {
        self.markScanStarted = markScanStarted
        self.markScanFailed = markScanFailed
    }

    init(health: HealthStore) {
        markScanStarted = { surface, date in
            try health.markScanStarted(surface, at: date)
        }
        markScanFailed = { surface, error, date in
            try health.markScanFailed(surface, error: error, at: date)
        }
    }
}
