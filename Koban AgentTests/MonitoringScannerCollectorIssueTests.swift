import Foundation
import GRDB
import Testing
@testable import Koban_Agent

// MARK: - MonitoringScannerCollectorIssueTests

struct MonitoringScannerCollectorIssueTests {
    @Test
    func partialCollectionIssuesCommitInventoryAndDegradeHealth() async throws {
        let database = try AppDatabase(DatabaseQueue())
        let inventory = InventoryRepository(database: database)
        let health = HealthStore(database: database)
        let item = Fixture.item(surface: .homebrew, name: "current")
        let issue = CollectorIssue(path: "/tmp/koban/unreadable.json", reason: "unreadable")
        let scanner = MonitoringScanner(
            configuration: configuration(maxScanWallClockSeconds: 1),
            inventory: inventory,
            commits: ScanCommitStore(database: database),
            health: health
        )

        try await scanner.runPipeline(PartialIssueCollector(
            surface: .homebrew,
            collectedSnapshot: CollectorSnapshot(items: [item], issues: [issue])
        ))

        let surfaceHealth = try #require(health.allHealth().first)
        #expect(surfaceHealth.state == .degraded)
        #expect(surfaceHealth.lastSuccessfulScanAt != nil)
        #expect(surfaceHealth.lastScanIssueCount == 1)
        #expect(surfaceHealth.lastFailure == HealthMessages.collectorVisibilityIssues(
            count: 1,
            firstIssue: issue
        ))
        #expect(try inventory.snapshot(for: .homebrew) == [item])
    }

    private func configuration(maxScanWallClockSeconds: Int) -> KobanConfiguration {
        var configuration = DefaultConfiguration.value
        configuration.watch.maxScanWallClockSeconds = maxScanWallClockSeconds
        return configuration
    }
}

// MARK: - PartialIssueCollector

private struct PartialIssueCollector: SurfaceCollector {
    let surface: MonitoredSurface
    let watchPaths: [String] = []
    let collectedSnapshot: CollectorSnapshot

    func snapshot() async throws -> [InventoryItem] {
        collectedSnapshot.items
    }

    func collect() async throws -> CollectorSnapshot {
        collectedSnapshot
    }
}
