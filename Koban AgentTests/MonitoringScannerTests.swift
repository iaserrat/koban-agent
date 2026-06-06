import Foundation
import GRDB
import Testing
@testable import Koban_Agent

// MARK: - MonitoringScannerTests

struct MonitoringScannerTests {
    @Test
    func timedOutPipelineMarksSurfaceDegradedAndKeepsPreviousInventory() async throws {
        let database = try AppDatabase(DatabaseQueue())
        let inventory = InventoryRepository(database: database)
        let health = HealthStore(database: database)
        let previous = Fixture.item(surface: .homebrew, name: "existing")
        let scanner = MonitoringScanner(
            configuration: configuration(maxScanWallClockSeconds: 0),
            inventory: inventory,
            commits: ScanCommitStore(database: database),
            health: health
        )

        try inventory.replace([previous], for: .homebrew)

        await #expect(throws: SurfaceScanTimeoutError(seconds: 0)) {
            try await scanner.runPipeline(SlowCollector(surface: .homebrew))
        }

        let surfaceHealth = try #require(health.allHealth().first)
        #expect(surfaceHealth.state == .degraded)
        #expect(surfaceHealth.lastFailure == HealthMessages.scanTimedOut(seconds: 0))
        #expect(try inventory.snapshot(for: .homebrew) == [previous])
    }

    @Test
    func successfulPipelineUsesConfiguredTimeoutBudget() async throws {
        let database = try AppDatabase(DatabaseQueue())
        let inventory = InventoryRepository(database: database)
        let health = HealthStore(database: database)
        let item = Fixture.item(surface: .homebrew, name: "current")
        let scanner = MonitoringScanner(
            configuration: configuration(maxScanWallClockSeconds: 1),
            inventory: inventory,
            commits: ScanCommitStore(database: database),
            health: health
        )

        try await scanner.runPipeline(ImmediateCollector(surface: .homebrew, items: [item]))

        let surfaceHealth = try #require(health.allHealth().first)
        #expect(surfaceHealth.state == .healthy)
        #expect(surfaceHealth.lastFailure == nil)
        #expect(try inventory.snapshot(for: .homebrew) == [item])
    }

    @Test
    func successfulPipelineUsesInjectedRuntimeForArtifacts() async throws {
        let database = try AppDatabase(DatabaseQueue())
        let inventory = InventoryRepository(database: database)
        let health = HealthStore(database: database)
        let events = EventStore(database: database)
        let item = Fixture.item(surface: .homebrew, name: ScannerRuntimeFixture.itemName)
        let eventID = UUID()
        let findingID = UUID()
        let runtime = ScanRuntimeSequence(
            dates: [
                ScannerRuntimeFixture.startedAt,
                ScannerRuntimeFixture.completedAt,
                ScannerRuntimeFixture.artifactTimestamp
            ],
            ids: [eventID, findingID]
        )
        let scanner = MonitoringScanner(
            configuration: configurationWithFindingRule(),
            inventory: inventory,
            commits: ScanCommitStore(database: database),
            health: health,
            runtime: runtime.scanRuntime
        )

        try await scanner.runPipeline(ImmediateCollector(surface: .homebrew, items: [item]))

        let surfaceHealth = try #require(health.allHealth().first)
        let event = try #require(events.allEvents().first)
        let finding = try #require(events.allFindings().first)
        #expect(surfaceHealth.lastScanStartedAt == ScannerRuntimeFixture.startedAt)
        #expect(surfaceHealth.lastScanCompletedAt == ScannerRuntimeFixture.completedAt)
        #expect(surfaceHealth.lastScanDurationMilliseconds == ScannerRuntimeFixture.durationMilliseconds)
        #expect(event.id == eventID)
        #expect(event.timestamp == ScannerRuntimeFixture.artifactTimestamp)
        #expect(finding.id == findingID)
        #expect(finding.timestamp == ScannerRuntimeFixture.artifactTimestamp)
    }

    @Test
    func failedFailureRecordingThrowsCompoundError() async throws {
        let database = try AppDatabase(DatabaseQueue())
        let inventory = InventoryRepository(database: database)
        let previous = Fixture.item(surface: .homebrew, name: ScannerFailureFixture.previousItemName)
        let scanner = MonitoringScanner(
            configuration: configuration(
                maxScanWallClockSeconds: ConfigurationDefaults.maxScanWallClockSeconds
            ),
            inventory: inventory,
            commits: ScanCommitStore(database: database),
            healthRecorder: ScanHealthRecorder(
                markScanStarted: { _, _ in },
                markScanFailed: { _, _, _ in throw ScannerFailureFixture.healthFailure }
            )
        )
        try inventory.replace([previous], for: .homebrew)

        await #expect(throws: ScanFailureRecordingError.self) {
            try await scanner.runPipeline(FailingCollector(surface: .homebrew))
        }
        #expect(try inventory.snapshot(for: .homebrew) == [previous])
    }

    private func configuration(maxScanWallClockSeconds: Int) -> KobanConfiguration {
        var configuration = DefaultConfiguration.value
        configuration.watch.maxScanWallClockSeconds = maxScanWallClockSeconds
        return configuration
    }

    private func configurationWithFindingRule() -> KobanConfiguration {
        var configuration = configuration(
            maxScanWallClockSeconds: ConfigurationDefaults.maxScanWallClockSeconds
        )
        configuration.rules = [
            HeuristicRule(
                id: ScannerRuntimeFixture.ruleID,
                surface: .homebrew,
                enabled: true,
                triggers: [.added],
                match: .always,
                severity: .notable,
                title: ScannerRuntimeFixture.ruleTitle,
                rationale: ScannerRuntimeFixture.ruleRationale
            )
        ]
        return configuration
    }
}

// MARK: - SlowCollector

private struct SlowCollector: SurfaceCollector {
    let surface: MonitoredSurface
    let watchPaths: [String] = []

    func snapshot() async throws -> [InventoryItem] {
        try await Task.sleep(for: .seconds(ConfigurationDefaults.maxScanWallClockSeconds))
        return []
    }
}

// MARK: - ImmediateCollector

private struct ImmediateCollector: SurfaceCollector {
    let surface: MonitoredSurface
    let watchPaths: [String] = []
    let items: [InventoryItem]

    func snapshot() async throws -> [InventoryItem] {
        items
    }
}

// MARK: - FailingCollector

private struct FailingCollector: SurfaceCollector {
    let surface: MonitoredSurface
    let watchPaths: [String] = []

    func snapshot() async throws -> [InventoryItem] {
        throw ScannerFailureFixture.scanFailure
    }
}

// MARK: - ScannerFailureFixture

private enum ScannerFailureFixture {
    static let previousItemName = "existing"
    static let scanFailure = ScannerFailure.scanFailed
    static let healthFailure = ScannerFailure.healthWriteFailed
}

// MARK: - ScannerFailure

private enum ScannerFailure: Error {
    case scanFailed
    case healthWriteFailed
}

// MARK: - ScannerRuntimeFixture

private enum ScannerRuntimeFixture {
    static let itemName = "runtime-package"
    static let ruleID = "runtime-rule"
    static let ruleTitle = "Runtime rule"
    static let ruleRationale = "Runtime rationale"
    static let startedSeconds: TimeInterval = 1000
    static let completedSeconds: TimeInterval = 1002
    static let artifactSeconds: TimeInterval = 1003
    static let durationMilliseconds = 2000.0
    static let startedAt = Date(timeIntervalSince1970: startedSeconds)
    static let completedAt = Date(timeIntervalSince1970: completedSeconds)
    static let artifactTimestamp = Date(timeIntervalSince1970: artifactSeconds)
}

// MARK: - ScanRuntimeSequence

private final class ScanRuntimeSequence: @unchecked Sendable {
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
