import Foundation
import Testing
@testable import Koban_Agent

// MARK: - PublishContentionStressTests

/// Stress/load gate for publish contention.
///
/// The expensive part of a publish is the read-model snapshot. The scheduler must collapse
/// a storm of publish requests into a bounded number of those reads, a stale cancelled
/// publish must never tear down a newer one, and a failing read must leave the last good
/// UI state untouched. The large-dataset case proves the publisher forwards linearly with
/// no fan-out (the logical latency budget; the charter forbids wall-clock assertions).
@MainActor
struct PublishContentionStressTests {
    private static let publishStorm = 5000
    private static let largeDatasetCount = 5000

    @Test
    func publishStormCoalescesToBoundedSnapshotReads() async {
        let scheduler = PublishScheduler()
        let probe = PublishStressProbe()

        await scheduler.schedule { await probe.run() }
        await probe.waitForStartedCount(1)

        for _ in 0 ..< Self.publishStorm {
            await scheduler.schedule { await probe.run() }
        }

        // The held publish blocks every other request: nothing extra ran yet.
        for _ in 0 ..< 16 {
            await Task.yield()
        }
        #expect(await probe.startedCount == 1)

        // Draining runs exactly one coalesced publish for the whole storm.
        await probe.finishNext()
        await probe.waitForStartedCount(2)
        await probe.finishNext()
        await probe.waitForDrainIdle()

        #expect(await probe.startedCount == 2)
        #expect(await probe.maxConcurrent == 1)
    }

    @Test
    func staleCancelledPublishCannotClearNewerWorkUnderStorm() async {
        let scheduler = PublishScheduler()
        let probe = PublishStressProbe()

        // Each iteration starts exactly one publish, so absolute counts track it precisely.
        let storm = 200
        for index in 1 ... storm {
            await scheduler.schedule { await probe.runUntilCancelled() }
            await probe.waitForStartedCount(index)
            await scheduler.cancel()
            await probe.waitForCancelledCount(index)
        }

        // A final live publish must survive the storm and complete.
        await scheduler.schedule { await probe.run() }
        await probe.waitForStartedCount(storm + 1)
        await probe.finishNext()
        await probe.waitForDrainIdle()

        #expect(await probe.cancelledCount == storm)
        #expect(await probe.maxConcurrent == 1)
    }

    @Test
    func repeatedReadModelFailuresPreserveLastGoodState() async {
        let appState = AppState()
        let goodEvent = Fixture.event(
            surface: .homebrew,
            itemName: "ripgrep",
            timestamp: Date(timeIntervalSince1970: 1)
        )
        let goodFinding = Fixture.finding(
            surface: .homebrew,
            itemName: "ripgrep",
            timestamp: Date(timeIntervalSince1970: 1)
        )

        let goodPublisher = makePublisher(appState: appState) {
            PublishedStateSnapshot(
                recentEvents: [goodEvent],
                recentFindings: [goodFinding],
                healthBySurface: [:],
                itemCountsBySurface: [.homebrew: 1]
            )
        }
        await goodPublisher.publish(queues: [])
        #expect(appState.readModelError == nil)

        let failingPublisher = makePublisher(appState: appState) {
            throw StressFailure.readModelUnavailable
        }
        for _ in 0 ..< 100 {
            await failingPublisher.publish(queues: [])
        }

        // Every failure recorded the error but left the last good state intact.
        #expect(appState.readModelError == String(describing: StressFailure.readModelUnavailable))
        #expect(appState.recentEvents == [goodEvent])
        #expect(appState.findings == [goodFinding])
        #expect(appState.summaries[.homebrew]?.itemCount == 1)
    }

    @Test
    func largeDatasetPublishForwardsLinearly() async {
        let appState = AppState()
        let timestamp = Date(timeIntervalSince1970: 1)
        let events = (0 ..< Self.largeDatasetCount).map {
            Fixture.event(surface: .homebrew, itemName: "pkg-\($0)", timestamp: timestamp)
        }
        let findings = (0 ..< Self.largeDatasetCount).map {
            Fixture.finding(surface: .homebrew, itemName: "pkg-\($0)", timestamp: timestamp)
        }
        let collectors = MonitoredSurface.allCases.map { StressCollector(surface: $0) }
        let publisher = MonitoringPublisher(
            snapshot: {
                PublishedStateSnapshot(
                    recentEvents: events,
                    recentFindings: findings,
                    healthBySurface: [:],
                    itemCountsBySurface: [.homebrew: Self.largeDatasetCount]
                )
            },
            summaryFactory: SurfaceSummaryFactory(freshnessPolicy: SurfaceFreshnessPolicy(maxAgeSeconds: 10)),
            collectors: collectors,
            appState: appState
        )

        await publisher.publish(queues: [])

        // No fan-out: the snapshot arrays forward 1:1 and there is one summary per surface.
        #expect(appState.recentEvents.count == Self.largeDatasetCount)
        #expect(appState.findings.count == Self.largeDatasetCount)
        #expect(appState.summaries.count == collectors.count)
    }

    private func makePublisher(
        appState: AppState,
        snapshot: @escaping () throws -> PublishedStateSnapshot
    ) -> MonitoringPublisher {
        MonitoringPublisher(
            snapshot: snapshot,
            summaryFactory: SurfaceSummaryFactory(freshnessPolicy: SurfaceFreshnessPolicy(maxAgeSeconds: 10)),
            collectors: [StressCollector(surface: .homebrew)],
            appState: appState
        )
    }
}

// MARK: - StressFailure

private enum StressFailure: Error {
    case readModelUnavailable
}

// MARK: - StressCollector

private struct StressCollector: SurfaceCollector {
    let surface: MonitoredSurface
    let watchPaths: [String] = []

    func snapshot() async throws -> [InventoryItem] {
        []
    }
}
