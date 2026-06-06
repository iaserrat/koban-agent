import Foundation
import GRDB
import Testing
@testable import Koban_Agent

// MARK: - SurfaceSummaryFactoryTests

struct SurfaceSummaryFactoryTests {
    @Test
    func includesScanQueueStateInSurfaceSummaries() throws {
        let factory = SurfaceSummaryFactory(
            freshnessPolicy: SurfaceFreshnessPolicy(maxAgeSeconds: 10)
        )
        let completedAt = Date(timeIntervalSince1970: 1)
        let health = telemetryHealth(completedAt: completedAt)

        let summaries = factory.summaries(
            for: [SummaryCollector(surface: .homebrew)],
            using: PublishedStateSnapshot(
                recentEvents: [],
                recentFindings: [],
                healthBySurface: [.homebrew: health],
                itemCountsBySurface: [.homebrew: 2]
            ),
            queues: [
                SurfaceScanQueueState(
                    surface: .homebrew,
                    isRunning: true,
                    runningScanID: nil,
                    hasPendingScan: true,
                    coalescedTriggerCount: 3
                )
            ],
            now: Date(timeIntervalSince1970: 2)
        )

        let summary = try #require(summaries[.homebrew])
        #expect(summary.itemCount == 1)
        #expect(summary.lastScanTelemetry == ScanTelemetry(
            itemCount: 1,
            eventCount: 4,
            findingCount: 2,
            addedItemCount: 2,
            modifiedItemCount: 1,
            removedItemCount: 1
        ))
        #expect(summary.healthState == .healthy)
        #expect(summary.lastScanCompletedAt == completedAt)
        #expect(summary.isScanRunning)
        #expect(summary.hasPendingScan)
        #expect(summary.coalescedTriggerCount == 3)
    }

    @Test
    func usesItemCountSnapshotWhenSurfaceHasNoHealth() throws {
        let factory = SurfaceSummaryFactory(
            freshnessPolicy: SurfaceFreshnessPolicy(maxAgeSeconds: 10)
        )

        let summaries = factory.summaries(
            for: [SummaryCollector(surface: .homebrew)],
            using: PublishedStateSnapshot(
                recentEvents: [],
                recentFindings: [],
                healthBySurface: [:],
                itemCountsBySurface: [.homebrew: 2]
            ),
            queues: [],
            now: Date(timeIntervalSince1970: 2)
        )

        let summary = try #require(summaries[.homebrew])
        #expect(summary.itemCount == 2)
        #expect(summary.lastScanTelemetry == ScanTelemetry(itemCount: 2))
    }

    @Test
    func marksSummaryStaleWhenLastSuccessfulScanIsTooOld() throws {
        let factory = SurfaceSummaryFactory(
            freshnessPolicy: SurfaceFreshnessPolicy(maxAgeSeconds: 10)
        )
        let completedAt = Date(timeIntervalSince1970: 1)
        let health = SurfaceHealth(
            surface: .homebrew,
            state: .healthy,
            lastScanCompletedAt: completedAt,
            lastSuccessfulScanAt: completedAt,
            lastScanDurationMilliseconds: 12,
            itemCount: 1
        )

        let summaries = factory.summaries(
            for: [SummaryCollector(surface: .homebrew)],
            using: PublishedStateSnapshot(
                recentEvents: [],
                recentFindings: [],
                healthBySurface: [.homebrew: health],
                itemCountsBySurface: [:]
            ),
            queues: [],
            now: Date(timeIntervalSince1970: 12)
        )

        let summary = try #require(summaries[.homebrew])
        #expect(summary.healthState == .stale)
    }

    @Test
    func exposesLastWatchIssueSeparatelyFromScanHealth() throws {
        let factory = SurfaceSummaryFactory(
            freshnessPolicy: SurfaceFreshnessPolicy(maxAgeSeconds: 10)
        )
        let watchIssueAt = Date(timeIntervalSince1970: 1)
        let scanAt = Date(timeIntervalSince1970: 2)
        let health = SurfaceHealth(
            surface: .homebrew,
            state: .healthy,
            lastScanCompletedAt: scanAt,
            lastSuccessfulScanAt: scanAt,
            lastWatchIssue: HealthMessages.watchEventsDropped,
            lastWatchIssueAt: watchIssueAt,
            itemCount: 1
        )

        let summaries = factory.summaries(
            for: [SummaryCollector(surface: .homebrew)],
            using: PublishedStateSnapshot(
                recentEvents: [],
                recentFindings: [],
                healthBySurface: [.homebrew: health],
                itemCountsBySurface: [:]
            ),
            queues: [],
            now: scanAt
        )

        let summary = try #require(summaries[.homebrew])
        #expect(summary.healthState == .healthy)
        #expect(summary.lastFailure == nil)
        #expect(summary.lastWatchIssue == HealthMessages.watchEventsDropped)
        #expect(summary.lastWatchIssueAt == watchIssueAt)
    }
}

private func telemetryHealth(completedAt: Date) -> SurfaceHealth {
    SurfaceHealth(
        surface: .homebrew,
        state: .healthy,
        lastScanCompletedAt: completedAt,
        lastSuccessfulScanAt: completedAt,
        lastScanDurationMilliseconds: TelemetryHealthFixture.scanDurationMilliseconds,
        itemCount: TelemetryHealthFixture.itemCount,
        lastScanEventCount: TelemetryHealthFixture.eventCount,
        lastScanFindingCount: TelemetryHealthFixture.findingCount,
        lastScanAddedItemCount: TelemetryHealthFixture.addedItemCount,
        lastScanModifiedItemCount: TelemetryHealthFixture.modifiedItemCount,
        lastScanRemovedItemCount: TelemetryHealthFixture.removedItemCount
    )
}

// MARK: - TelemetryHealthFixture

private enum TelemetryHealthFixture {
    static let addedItemCount = 2
    static let eventCount = 4
    static let findingCount = 2
    static let itemCount = 1
    static let modifiedItemCount = 1
    static let removedItemCount = 1
    static let scanDurationMilliseconds = 12.0
}

// MARK: - SummaryCollector

private struct SummaryCollector: SurfaceCollector {
    let surface: MonitoredSurface
    let watchPaths: [String] = []

    func snapshot() async throws -> [InventoryItem] {
        []
    }
}
