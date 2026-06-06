import Foundation
import GRDB

struct ScanCommitStore {
    let database: AppDatabase
    let retention: StorageRetentionPolicy
    let syncSettings: SyncSettings

    init(
        database: AppDatabase,
        retention: StorageRetentionPolicy = StorageRetentionPolicy(
            settings: DefaultConfiguration.value.persistence
        ),
        syncSettings: SyncSettings = DefaultConfiguration.value.sync
    ) {
        self.database = database
        self.retention = retention
        self.syncSettings = syncSettings
    }

    func commitBaseline(
        surface: MonitoredSurface,
        items: [InventoryItem],
        issues: [CollectorIssue] = [],
        durationMilliseconds: Double,
        completedAt: Date
    ) throws {
        try database.writer.write { db in
            try replace(items, for: surface, in: db)
            try db.execute(
                sql: "INSERT OR IGNORE INTO \(StorageNames.baselineTable) (surface) VALUES (?)",
                arguments: [surface]
            )
            try enqueueBaselineSyncEvents(surface: surface, items: items, collectedAt: completedAt, in: db)
            try markScanSucceeded(
                surface,
                telemetry: ScanTelemetry(itemCount: items.count),
                issues: issues,
                durationMilliseconds: durationMilliseconds,
                at: completedAt,
                in: db
            )
        }
    }

    func commitScan(_ commit: ScanCommit) throws {
        try database.writer.write { db in
            try replace(commit.current, previous: commit.previous, in: db)
            for event in commit.events {
                try event.insert(db)
            }
            for finding in commit.findings {
                try finding.insert(db)
            }
            try enqueueSyncEvents(for: commit, in: db)
            try retention.apply(in: db)
            try markScanSucceeded(
                commit.surface,
                telemetry: ScanTelemetry(
                    items: commit.current,
                    events: commit.events,
                    findings: commit.findings
                ),
                issues: commit.issues,
                durationMilliseconds: commit.durationMilliseconds,
                at: commit.completedAt,
                in: db
            )
        }
    }

    private func replace(
        _ items: [InventoryItem],
        for surface: MonitoredSurface,
        in db: Database
    ) throws {
        let previous = try InventoryItem
            .filter(Column(StorageColumns.surface) == surface)
            .fetchAll(db)
        try replace(items, previous: previous, in: db)
    }

    private func replace(
        _ items: [InventoryItem],
        previous: [InventoryItem],
        in db: Database
    ) throws {
        let previousByID = Dictionary(uniqueKeysWithValues: previous.map { ($0.id, $0) })
        let currentIDs = Set(items.map(\.id))

        for removed in previous where currentIDs.contains(removed.id) == false {
            try removed.delete(db)
        }
        for item in items where previousByID[item.id] != item {
            try item.save(db)
        }
    }

    private func markScanSucceeded(
        _ surface: MonitoredSurface,
        telemetry: ScanTelemetry,
        issues: [CollectorIssue] = [],
        durationMilliseconds: Double,
        at date: Date,
        in db: Database
    ) throws {
        var health = try SurfaceHealth.fetchOne(db, key: surface.rawValue)
            ?? SurfaceHealth(surface: surface)
        health.recordSuccess(
            telemetry: telemetry,
            issues: issues,
            durationMilliseconds: durationMilliseconds,
            at: date
        )
        try health.save(db)
    }
}
