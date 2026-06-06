import GRDB
import Testing
@testable import Koban_Agent

// MARK: - MonitoringScannerCancellationTests

struct MonitoringScannerCancellationTests {
    @Test
    func cancelledPipelineDoesNotMarkSurfaceDegraded() async throws {
        let database = try AppDatabase(DatabaseQueue())
        let inventory = InventoryRepository(database: database)
        let health = HealthStore(database: database)
        let previous = Fixture.item(surface: .homebrew, name: "existing")
        let scanner = MonitoringScanner(
            configuration: configuration(),
            inventory: inventory,
            commits: ScanCommitStore(database: database),
            health: health
        )

        try inventory.replace([previous], for: .homebrew)

        await #expect(throws: CancellationError.self) {
            try await scanner.runPipeline(CancelledCollector(surface: .homebrew))
        }

        let surfaceHealth = try #require(health.allHealth().first)
        #expect(surfaceHealth.state == .idle)
        #expect(surfaceHealth.lastFailure == nil)
        #expect(surfaceHealth.lastScanCompletedAt == nil)
        #expect(try inventory.snapshot(for: .homebrew) == [previous])
    }

    @Test
    func cancelledBaselineDoesNotMarkSurfaceDegraded() async throws {
        let database = try AppDatabase(DatabaseQueue())
        let inventory = InventoryRepository(database: database)
        let health = HealthStore(database: database)
        let scanner = MonitoringScanner(
            configuration: configuration(),
            inventory: inventory,
            commits: ScanCommitStore(database: database),
            health: health
        )

        await #expect(throws: CancellationError.self) {
            try await scanner.establishBaseline(CancelledCollector(surface: .homebrew))
        }

        let surfaceHealth = try #require(health.allHealth().first)
        #expect(surfaceHealth.state == .idle)
        #expect(surfaceHealth.lastFailure == nil)
        #expect(surfaceHealth.lastScanCompletedAt == nil)
        #expect(try inventory.snapshot(for: .homebrew).isEmpty)
    }

    private func configuration() -> KobanConfiguration {
        var configuration = DefaultConfiguration.value
        configuration.watch.maxScanWallClockSeconds = ConfigurationDefaults.maxScanWallClockSeconds
        return configuration
    }
}

// MARK: - CancelledCollector

private struct CancelledCollector: SurfaceCollector {
    let surface: MonitoredSurface
    let watchPaths: [String] = []

    func snapshot() async throws -> [InventoryItem] {
        throw CancellationError()
    }
}
