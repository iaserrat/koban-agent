import Foundation
import GRDB

// MARK: - ScanCommitStore

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
        findings: [Finding] = [],
        issues: [CollectorIssue] = [],
        durationMilliseconds: Double,
        completedAt: Date
    ) throws {
        try database.writer.write { db in
            let persistedFindings = try nonDuplicatePresentFindings(findings, existingFindings: [], in: db)
            try replace(items, for: surface, in: db)
            for finding in persistedFindings {
                try finding.insert(db)
            }
            try db.execute(
                sql: "INSERT OR IGNORE INTO \(StorageNames.baselineTable) (surface) VALUES (?)",
                arguments: [surface]
            )
            try enqueueBaselineSyncEvents(
                surface: surface,
                items: items,
                findings: persistedFindings,
                collectedAt: completedAt,
                in: db
            )
            try markScanSucceeded(
                surface,
                telemetry: ScanTelemetry(itemCount: items.count, findingCount: persistedFindings.count),
                issues: issues,
                durationMilliseconds: durationMilliseconds,
                at: completedAt,
                in: db
            )
        }
    }

    func commitScan(_ commit: ScanCommit) throws {
        try database.writer.write { db in
            let presentFindings = try nonDuplicatePresentFindings(
                commit.presentFindings,
                existingFindings: commit.findings,
                in: db
            )
            try replace(commit.current, previous: commit.previous, in: db)
            for event in commit.events {
                try event.insert(db)
            }
            for finding in commit.findings + presentFindings {
                try finding.insert(db)
            }
            try enqueueSyncEvents(for: commit, findings: commit.findings + presentFindings, in: db)
            try retention.apply(in: db)
            try markScanSucceeded(
                commit.surface,
                telemetry: ScanTelemetry(
                    items: commit.current,
                    events: commit.events,
                    findings: commit.findings + presentFindings
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

// MARK: - Present finding dedupe

extension ScanCommitStore {
    private func nonDuplicatePresentFindings(
        _ findings: [Finding],
        existingFindings: [Finding],
        in db: Database
    ) throws -> [Finding] {
        var seen = Set(existingFindings.map(findingKey))
        for finding in findings {
            let matching = try Finding
                .filter(Column(StorageColumns.surface) == finding.surface)
                .filter(Column(StorageColumns.itemID) == finding.itemID)
                .filter(Column(StorageColumns.ruleID) == finding.ruleID)
                .fetchOne(db)
            if let matching {
                seen.insert(findingKey(matching))
            }
        }

        var unique: [Finding] = []
        for finding in findings where seen.contains(findingKey(finding)) == false {
            seen.insert(findingKey(finding))
            unique.append(finding)
        }
        return unique
    }

    private func findingKey(_ finding: Finding) -> String {
        [
            finding.surface.rawValue,
            finding.itemID,
            finding.ruleID
        ].joined(separator: StorageNames.findingIdentitySeparator)
    }
}
