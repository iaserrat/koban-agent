import Foundation
import GRDB

struct HealthStore {
    let database: AppDatabase

    func recordWatchPlan(_ plan: WatchPlan) throws {
        try database.writer.write { db in
            for interest in plan.interests {
                var health = try currentHealth(for: interest.surface, in: db)
                health.watchPathCount = interest.paths.count
                try health.save(db)
            }
        }
    }

    func markScanStarted(_ surface: MonitoredSurface, at date: Date) throws {
        try database.writer.write { db in
            var health = try currentHealth(for: surface, in: db)
            health.lastScanStartedAt = date
            try health.save(db)
        }
    }

    func markScanSucceeded(
        _ surface: MonitoredSurface,
        itemCount: Int,
        durationMilliseconds: Double,
        at date: Date
    ) throws {
        try markScanSucceeded(
            surface,
            telemetry: ScanTelemetry(itemCount: itemCount),
            durationMilliseconds: durationMilliseconds,
            at: date
        )
    }

    func markScanSucceeded(
        _ surface: MonitoredSurface,
        telemetry: ScanTelemetry,
        issues: [CollectorIssue] = [],
        durationMilliseconds: Double,
        at date: Date
    ) throws {
        try database.writer.write { db in
            var health = try currentHealth(for: surface, in: db)
            health.recordSuccess(
                telemetry: telemetry,
                issues: issues,
                durationMilliseconds: durationMilliseconds,
                at: date
            )
            try health.save(db)
        }
    }

    func markScanFailed(_ surface: MonitoredSurface, error: any Error, at date: Date) throws {
        try markDegraded(surface, reason: String(describing: error), at: date)
    }

    func markDegraded(_ surface: MonitoredSurface, reason: String, at date: Date) throws {
        try database.writer.write { db in
            var health = try currentHealth(for: surface, in: db)
            health.state = .degraded
            health.lastScanCompletedAt = date
            health.lastFailure = reason
            try health.save(db)
        }
    }

    func markWatchDegraded(_ surface: MonitoredSurface, reason: String, at date: Date) throws {
        try database.writer.write { db in
            var health = try currentHealth(for: surface, in: db)
            health.state = .degraded
            health.lastWatchIssue = reason
            health.lastWatchIssueAt = date
            try health.save(db)
        }
    }

    func allHealth() throws -> [SurfaceHealth] {
        try database.reader.read { db in
            try SurfaceHealth.order(Column("surface")).fetchAll(db)
        }
    }

    private func currentHealth(for surface: MonitoredSurface, in db: Database) throws -> SurfaceHealth {
        try SurfaceHealth.fetchOne(db, key: surface.rawValue) ?? SurfaceHealth(surface: surface)
    }
}
