import Foundation
import GRDB
import Testing
@testable import Koban_Agent

// MARK: - HealthStoreTests

struct HealthStoreTests {
    @Test
    func recordsWatchPlanCountsPerSurface() throws {
        let store = try makeStore()
        let plan = WatchPlan(
            paths: ["/tmp/a", "/tmp/b"],
            interests: [
                WatchInterest(surface: .codexConfig, paths: ["/tmp/a", "/tmp/b"])
            ]
        )

        try store.recordWatchPlan(plan)

        let health = try #require(store.allHealth().first)
        #expect(health.surface == .codexConfig)
        #expect(health.watchPathCount == 2)
        #expect(health.state == .idle)
    }

    @Test
    func recordsSuccessfulScanTelemetry() throws {
        let store = try makeStore()
        let startedAt = Date(timeIntervalSince1970: 1)
        let completedAt = Date(timeIntervalSince1970: 2)

        try store.markScanStarted(.homebrew, at: startedAt)
        try store.markScanSucceeded(
            .homebrew,
            telemetry: ScanTelemetry(
                itemCount: 42,
                eventCount: 6,
                findingCount: 2,
                addedItemCount: 3,
                modifiedItemCount: 2,
                removedItemCount: 1
            ),
            durationMilliseconds: 12,
            at: completedAt
        )

        let health = try #require(store.allHealth().first)
        #expect(health.state == .healthy)
        #expect(health.lastScanStartedAt == startedAt)
        #expect(health.lastScanCompletedAt == completedAt)
        #expect(health.lastSuccessfulScanAt == completedAt)
        #expect(health.lastFailure == nil)
        #expect(health.lastScanDurationMilliseconds == 12)
        #expect(health.lastScanTelemetry == ScanTelemetry(
            itemCount: 42,
            eventCount: 6,
            findingCount: 2,
            addedItemCount: 3,
            modifiedItemCount: 2,
            removedItemCount: 1
        ))
    }

    @Test
    func recordsFailedScanAsDegradedWithoutClearingLastSuccess() throws {
        let store = try makeStore()
        let successAt = Date(timeIntervalSince1970: 1)
        let failureAt = Date(timeIntervalSince1970: 2)

        try store.markScanSucceeded(.homebrew, itemCount: 1, durationMilliseconds: 10, at: successAt)
        try store.markScanFailed(.homebrew, error: TestError(), at: failureAt)

        let health = try #require(store.allHealth().first)
        #expect(health.state == .degraded)
        #expect(health.lastScanCompletedAt == failureAt)
        #expect(health.lastSuccessfulScanAt == successAt)
        #expect(health.lastFailure == "TestError()")
    }

    @Test
    func recordsWatchDegradationReason() throws {
        let store = try makeStore()
        let failureAt = Date(timeIntervalSince1970: 1)

        try store.markWatchDegraded(
            .codexConfig,
            reason: HealthMessages.watchStreamUnavailable,
            at: failureAt
        )

        let health = try #require(store.allHealth().first)
        #expect(health.state == .degraded)
        #expect(health.lastScanCompletedAt == nil)
        #expect(health.lastFailure == nil)
        #expect(health.lastWatchIssue == HealthMessages.watchStreamUnavailable)
        #expect(health.lastWatchIssueAt == failureAt)
    }

    @Test
    func successfulScanPreservesLastWatchIssue() throws {
        let store = try makeStore()
        let watchIssueAt = Date(timeIntervalSince1970: 1)
        let scanAt = Date(timeIntervalSince1970: 2)

        try store.markWatchDegraded(
            .codexConfig,
            reason: HealthMessages.watchEventsDropped,
            at: watchIssueAt
        )
        try store.markScanSucceeded(.codexConfig, itemCount: 4, durationMilliseconds: 6, at: scanAt)

        let health = try #require(store.allHealth().first)
        #expect(health.state == .healthy)
        #expect(health.lastFailure == nil)
        #expect(health.lastWatchIssue == HealthMessages.watchEventsDropped)
        #expect(health.lastWatchIssueAt == watchIssueAt)
    }

    @Test
    func inventorySchemaPersistsKind() throws {
        let database = try AppDatabase(DatabaseQueue())
        let repository = InventoryRepository(database: database)
        let item = Fixture.item(surface: .homebrew, kind: .mcpServer, name: "visual-studio-code")

        try repository.replace([item], for: .homebrew)

        #expect(try repository.snapshot(for: .homebrew).first?.kind == .mcpServer)
    }

    private func makeStore() throws -> HealthStore {
        try HealthStore(database: AppDatabase(DatabaseQueue()))
    }
}

// MARK: - TestError

private struct TestError: Error {}
