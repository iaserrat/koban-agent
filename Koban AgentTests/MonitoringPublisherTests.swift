import Foundation
import Testing
@testable import Koban_Agent

// MARK: - MonitoringPublisherTests

@MainActor
struct MonitoringPublisherTests {
    @Test
    func failedPublishRecordsReadModelFailureAndPreservesLastGoodState() async {
        let appState = AppState()
        let event = Fixture.event(
            surface: .homebrew,
            itemName: "ripgrep",
            timestamp: PublisherFixture.timestamp
        )
        let finding = Fixture.finding(
            surface: .homebrew,
            itemName: "ripgrep",
            timestamp: PublisherFixture.timestamp
        )
        appState.refresh(
            summaries: [.homebrew: SurfaceSummary(itemCount: 1)],
            events: [event],
            findings: [finding]
        )
        let revision = appState.revision
        let publisher = MonitoringPublisher(
            snapshot: { throw PublisherFixture.failure },
            summaryFactory: PublisherFixture.summaryFactory,
            collectors: [PublisherCollector(surface: .homebrew)],
            appState: appState
        )

        await publisher.publish(queues: [])

        #expect(appState.readModelError == String(describing: PublisherFixture.failure))
        #expect(appState.revision == revision + 1)
        #expect(appState.recentEvents == [event])
        #expect(appState.findings == [finding])
        #expect(appState.summaries[.homebrew]?.itemCount == 1)
    }

    @Test
    func successfulPublishClearsPreviousReadModelFailure() async {
        let appState = AppState()
        appState.recordReadModelFailure(String(describing: PublisherFixture.failure))
        let event = Fixture.event(
            surface: .homebrew,
            itemName: "ripgrep",
            timestamp: PublisherFixture.timestamp
        )
        let publisher = MonitoringPublisher(
            snapshot: {
                PublishedStateSnapshot(
                    recentEvents: [event],
                    recentFindings: [],
                    healthBySurface: [:],
                    itemCountsBySurface: [.homebrew: 2]
                )
            },
            summaryFactory: PublisherFixture.summaryFactory,
            collectors: [PublisherCollector(surface: .homebrew)],
            appState: appState
        )

        await publisher.publish(queues: [])

        #expect(appState.readModelError == nil)
        #expect(appState.recentEvents == [event])
        #expect(appState.summaries[.homebrew]?.itemCount == 2)
    }
}

// MARK: - PublisherFixture

private enum PublisherFixture {
    static let failure = PublisherFailure.readModelUnavailable
    static let maxFreshScanAgeSeconds = 10
    static let summaryFactory = SurfaceSummaryFactory(
        freshnessPolicy: SurfaceFreshnessPolicy(maxAgeSeconds: maxFreshScanAgeSeconds)
    )
    static let timestamp = Date(timeIntervalSince1970: 1)
}

// MARK: - PublisherFailure

private enum PublisherFailure: Error {
    case readModelUnavailable
}

// MARK: - PublisherCollector

private struct PublisherCollector: SurfaceCollector {
    let surface: MonitoredSurface
    let watchPaths: [String] = []

    func snapshot() async throws -> [InventoryItem] {
        []
    }
}
