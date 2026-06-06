import Foundation
import GRDB
import Testing
@testable import Koban_Agent

// MARK: - PresentMonitoringScannerTests

struct PresentMonitoringScannerTests {
    @Test
    func pipelineRaisesPresentFindingForUnchangedInventory() async throws {
        let database = try AppDatabase(DatabaseQueue())
        let inventory = InventoryRepository(database: database)
        let health = HealthStore(database: database)
        let events = EventStore(database: database)
        let item = Fixture.item(surface: .homebrew, name: Self.itemName)
        let findingID = UUID()
        let runtime = PresentScanRuntimeSequence(
            dates: [Self.startedAt, Self.completedAt, Self.artifactTimestamp],
            ids: [findingID]
        )
        let scanner = makeScanner(
            database: database,
            inventory: inventory,
            health: health,
            runtime: runtime.scanRuntime
        )
        try inventory.replace([item], for: .homebrew)

        try await scanner.runPipeline(PresentImmediateCollector(surface: .homebrew, items: [item]))

        #expect(try events.allEvents().isEmpty)
        let finding = try #require(events.allFindings().first)
        #expect(finding.id == findingID)
        #expect(finding.ruleID == Self.ruleID)
        #expect(finding.itemName == Self.itemName)
        let surfaceHealth = try #require(health.allHealth().first)
        #expect(surfaceHealth.lastScanTelemetry == ScanTelemetry(itemCount: 1, findingCount: 1))
    }

    @Test
    func repeatedPipelineDoesNotDuplicatePresentFinding() async throws {
        let database = try AppDatabase(DatabaseQueue())
        let inventory = InventoryRepository(database: database)
        let health = HealthStore(database: database)
        let events = EventStore(database: database)
        let item = Fixture.item(surface: .homebrew, name: Self.itemName)
        let runtime = PresentScanRuntimeSequence(
            dates: [
                Date(timeIntervalSince1970: Self.firstStartedSeconds),
                Date(timeIntervalSince1970: Self.firstCompletedSeconds),
                Date(timeIntervalSince1970: Self.firstArtifactSeconds),
                Date(timeIntervalSince1970: Self.secondStartedSeconds),
                Date(timeIntervalSince1970: Self.secondCompletedSeconds),
                Date(timeIntervalSince1970: Self.secondArtifactSeconds)
            ],
            ids: [UUID(), UUID()]
        )
        let scanner = makeScanner(
            database: database,
            inventory: inventory,
            health: health,
            runtime: runtime.scanRuntime
        )
        try inventory.replace([item], for: .homebrew)

        try await scanner.runPipeline(PresentImmediateCollector(surface: .homebrew, items: [item]))
        try await scanner.runPipeline(PresentImmediateCollector(surface: .homebrew, items: [item]))

        #expect(try events.allFindings().count == 1)
        let surfaceHealth = try #require(health.allHealth().first)
        #expect(surfaceHealth.lastScanTelemetry == ScanTelemetry(itemCount: 1))
    }

    @Test
    func baselineRaisesPresentFindingWithoutActivityEvent() async throws {
        let database = try AppDatabase(DatabaseQueue())
        let inventory = InventoryRepository(database: database)
        let health = HealthStore(database: database)
        let events = EventStore(database: database)
        let item = Fixture.item(surface: .homebrew, name: Self.itemName)
        let findingID = UUID()
        let runtime = PresentScanRuntimeSequence(
            dates: [Self.startedAt, Self.completedAt, Self.artifactTimestamp],
            ids: [findingID]
        )
        let scanner = makeScanner(
            database: database,
            inventory: inventory,
            health: health,
            runtime: runtime.scanRuntime
        )

        try await scanner.establishBaseline(PresentImmediateCollector(surface: .homebrew, items: [item]))

        #expect(try events.allEvents().isEmpty)
        let finding = try #require(events.allFindings().first)
        #expect(finding.id == findingID)
        #expect(try inventory.isBaselined(.homebrew))
        let surfaceHealth = try #require(health.allHealth().first)
        #expect(surfaceHealth.lastScanTelemetry == ScanTelemetry(itemCount: 1, findingCount: 1))
    }

    private func makeScanner(
        database: AppDatabase,
        inventory: InventoryRepository,
        health: HealthStore,
        runtime: ScanRuntime
    ) -> MonitoringScanner {
        MonitoringScanner(
            configuration: Self.configuration,
            inventory: inventory,
            commits: ScanCommitStore(database: database),
            health: health,
            runtime: runtime
        )
    }

    private static var configuration: KobanConfiguration {
        var configuration = DefaultConfiguration.value
        configuration.rules = [
            HeuristicRule(
                id: ruleID,
                surface: .homebrew,
                enabled: true,
                triggers: [.present],
                match: .fieldContainsAny(field: .name, values: [itemName]),
                severity: .critical,
                title: ruleTitle,
                rationale: ruleRationale
            )
        ]
        return configuration
    }

    private static let itemName = "runtime-package"
    private static let ruleID = "runtime-rule"
    private static let ruleTitle = "Runtime rule"
    private static let ruleRationale = "Runtime rationale"
    private static let startedSeconds: TimeInterval = 1000
    private static let completedSeconds: TimeInterval = 1002
    private static let artifactSeconds: TimeInterval = 1003
    private static let firstStartedSeconds: TimeInterval = 2000
    private static let firstCompletedSeconds: TimeInterval = 2001
    private static let firstArtifactSeconds: TimeInterval = 2002
    private static let secondStartedSeconds: TimeInterval = 2003
    private static let secondCompletedSeconds: TimeInterval = 2004
    private static let secondArtifactSeconds: TimeInterval = 2005
    private static let startedAt = Date(timeIntervalSince1970: startedSeconds)
    private static let completedAt = Date(timeIntervalSince1970: completedSeconds)
    private static let artifactTimestamp = Date(timeIntervalSince1970: artifactSeconds)
}

// MARK: - PresentImmediateCollector

private struct PresentImmediateCollector: SurfaceCollector {
    let surface: MonitoredSurface
    let watchPaths: [String] = []
    let items: [InventoryItem]

    func snapshot() async throws -> [InventoryItem] {
        items
    }
}

// MARK: - PresentScanRuntimeSequence

private final class PresentScanRuntimeSequence: @unchecked Sendable {
    private let lock = NSLock()
    private var dates: [Date]
    private var ids: [UUID]

    init(dates: [Date], ids: [UUID]) {
        self.dates = dates
        self.ids = ids
    }

    var scanRuntime: ScanRuntime {
        ScanRuntime(now: nextDate, makeID: nextID)
    }

    private func nextDate() -> Date {
        lock.lock()
        defer { lock.unlock() }
        return dates.removeFirst()
    }

    private func nextID() -> UUID {
        lock.lock()
        defer { lock.unlock() }
        return ids.removeFirst()
    }
}
